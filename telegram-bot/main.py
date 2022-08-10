import os
import telegram
import traceback
from typing import Any

from google.api_core.extended_operation import ExtendedOperation
from google.cloud import compute_v1


class NotAddressedToBotRequest(Exception):
    pass


class NotValidBotRequest(Exception):
    pass


class MinecraftServerBot:
    """
    chat_id: The only verified chat where the bot eligible to receive messages.
    instance_id: id of Compute Engine instance to stop/start
    project_id: project ID or project number of the Cloud project your instance belongs to.
    zone_id: id of the zone your instance belongs to.
    telegram_api: Authenticated with Telegram API bot
    """
    debug_on = False
    chat_id = None
    instance_id = None
    project_id = None
    zone_id = None
    telegram_api = None
    commands = None

    def __init__(self, debug_on=False):
        self.debug_on = debug_on
        self.telegram_api = telegram.Bot(token=os.environ["TELEGRAM_TOKEN"])
        self.telegram_bot_name = str(os.environ["TELEGRAM_BOT_NAME"])
        self.chat_id = str(os.environ["CHAT_ID"])
        self.instance_id = str(os.environ["INSTANCE_ID"])
        self.project_id = str(os.environ["PROJECT_ID"])
        self.zone_id = str(os.environ["ZONE_ID"])

        self.commands = {
            "start": self.server_start,
            "stop": self.server_stop,
            "status": self.server_status,
            "help": self.help
        }

    def __wait_for_extended_operation(
        self, operation: ExtendedOperation, verbose_name: str = "operation", timeout: int = 90
    ) -> Any:
        """
        This method will wait for the extended (long-running) operation to
        complete. If the operation is successful, it will return its result.
        If the operation ends with an error, an exception will be raised.
        If there were any warnings during the execution of the operation
        they will be printed to sys.stderr.

        Args:
            operation: a long-running operation you want to wait on.
            verbose_name: (optional) a more verbose name of the operation,
                used only during error and warning reporting.
            timeout: how long (in seconds) to wait for operation to finish.
                If None, wait indefinitely.

        Returns:
            Whatever the operation.result() returns.

        Raises:
            This method will raise the exception received from `operation.exception()`
            or RuntimeError if there is no exception set, but there is an `error_code`
            set for the `operation`.

            In case of an operation taking longer than `timeout` seconds to complete,
            a `concurrent.futures.TimeoutError` will be raised.
        """
        result = operation.result(timeout=timeout)

        if operation.error_code:
            self.error(
                f"Error during {verbose_name}: [Code: {operation.error_code}]: {operation.error_message}"
            )
            self.error(f"Operation ID: {operation.name}")
            raise operation.exception() or RuntimeError(operation.error_message)

        if operation.warnings:
            self.info(f"Warnings during {verbose_name}:\n",)
            for warning in operation.warnings:
                self.info(f" - {warning.code}: {warning.message}")

        return result

    def server_start(self) -> None:
        """
        Starts a stopped Google Compute Engine instance.
        """
        self.debug("Starting server.")
        self.reply(f"The server is starting... It may take a few minutes.")
        instance_client = compute_v1.InstancesClient()

        operation = instance_client.start(
            project=self.project_id, zone=self.zone_id, instance=self.instance_id
        )
        self.__wait_for_extended_operation(operation, "instance starting")
        self.info(f"An instance {self.project_id}/{self.instance_id} was successfully started.")
        self.reply(f"The server was started! Please, wait until it is ready.")
        return

    def server_stop(self) -> None:
        """
        Stops a running Google Compute Engine instance.
        """
        self.debug("Stopping server.")
        self.reply(f"The server is stopping... It may take a few minutes.")
        instance_client = compute_v1.InstancesClient()

        operation = instance_client.stop(
            project=self.project_id, zone=self.zone_id, instance=self.instance_id
        )
        self.__wait_for_extended_operation(operation, "instance stopping")
        self.info(f"An instance {self.project_id}/{self.instance_id} was successfully stopped.")
        self.reply(f"The server was stopped!")
        return

    def server_status(self) -> None:
        """ Returns whether the instance is running or not. """
        self.debug("Getting server status.")
        instance_client = compute_v1.InstancesClient()
        result = instance_client.get(
            project=self.project_id, zone=self.zone_id, instance=self.instance_id
        )
        self.debug(f"Result {result.status}")
        if result.status == "RUNNING":
            self.reply("The server is running.")
        elif result.status == "TERMINATED":
            self.reply("The server is stopped.")
        else:
            self.reply(f"The server status: {result.status}")
            self.error(f"Unknown server status: {result.status}")

    def help(self) -> None:
        """ Replies with a help message in the chat. """
        message = "The following is a list of available commands:\n" + \
                  "- **start**: Starts server\n" + \
                  "- **stop**: Stops server\n" + \
                  "- **status**: Shows the server status"
        self.reply(message)

    def get_message(self, request: dict) -> str:
        """ Returns the message of the request which caused the webhook to trigger."""
        self.debug("Getting message content.")
        update = telegram.Update.de_json(request.get_json(force=True), self.telegram_api)
        return update.message.text

    def verify_method(self, request):
        """ Verifies that the request type is POST."""
        self.debug(f"Request:\n{request}")
        if request.method != "POST":
            self.debug(f"Request method is different from POST \"{request.method}\" ignoring.")
            raise NotAddressedToBotRequest(f"Request method is different from POST \"{request.method}\", "
                                           f"ignoring.")
        self.debug("The method is valid.")

    def verify_chat(self, request: dict) -> None:
        """
        Makes sure the command message was received from the CORRECT telegram chat
        and that the message is a new one (not edited).
        """
        self.debug("Verifying chat.")
        request_json = request.get_json(force=True)
        update = telegram.Update.de_json(request_json, self.telegram_api)
        self.debug(f"Request JSON:\n{request_json}")
        self.debug(f"Update:\n{update}")

        """
        Makes sure that request contains the message (e.g. it is not an edited message,
        otherwise it would have and edited_message filed instead.)
        """
        if not update.message:
            self.debug(f"The request was caused by message editing ignoring.")
            raise NotAddressedToBotRequest(f"The request was cause by message editing ignoring.")

        if str(update.message.chat.id) == str(self.chat_id):
            self.info("The chat_id is correct, proceeding with the request.")
        else:
            self.debug(f"The chat_id \"{update.message.chat.id}\" "
                       f"is not eligible for receiving commands, ignoring.")
            self.debug(f"Valid chat_id: {self.chat_id}")
            raise NotAddressedToBotRequest(f"The chat_id \"{update.message.chat.id}\" "
                                           f"is not eligible for receiving commands, ignoring.")

        self.debug("The chat is valid.")

    def verify_message(self, request) -> str:
        """
        Verifies that the message has a Minecraft Server bot tagged and contains valid command.
        :returns string which contains the command to the bot.
        """
        self.debug("Verifying message.")
        message = self.get_message(request)
        self.debug(f"Checking if tag @{self.telegram_bot_name} is present in the message \"{message}\".")

        if f"@{self.telegram_bot_name}" in message:
            command = " ".join([substr for substr in message.split() if substr[0] != '@'])
            self.debug(f"Retrieved command: {command}")
            if self.is_command_exist(command):
                self.debug(f"The command \"{command}\" is valid.")
                return command
            else:
                self.error(f"The command {command} is not valid.")
                raise NotValidBotRequest(f"The command **{command}** is not valid. Use **help**. "
                                         f"Use help to see valid commands.")
        else:
            self.debug(f"Message wasn't addressed to the bot, ignoring.")
            raise NotAddressedToBotRequest(f"Message wasn't addressed to the bot, ignoring.")

    def is_command_exist(self, name) -> bool:
        """
        Checks that the command exists.
        :returns True or False
        """
        if name in self.commands.keys():
            return True
        return False

    def run_command_by_name(self, name: str, *args, **kwargs):
        self.debug(f"Running command by name \"{name}\".")
        result = None
        if self.is_command_exist(name):
            self.debug(f"The name \"{name}\" is valid, executing corresponding command.")
            result = self.commands[name](*args, **kwargs)
        return result

    def reply(self, message: str) -> None:
        # TODO: Mar
        self.telegram_api.sendMessage(
            chat_id=self.chat_id,
            text=message,
            parse_mode="Markdown"
        )

    # TODO: replace with logging, instead of printing
    def info(self, message: str) -> None:
        self.log(message, level="INFO")

    def error(self, message: str) -> None:
        self.log(message, level="ERROR")

    def debug(self, message: str) -> None:
        if self.debug_on:
            self.log(message, level="DEBUG")

    def log(self, message: str, level="INFO") -> None:
        print(f"[{level}] {message}.")


def telegram_bot(request):
    """
    Main function which is triggered by Telegram webhook.
    """
    try:
        bot = MinecraftServerBot(debug_on=True)
    except Exception as ex:
        return "500"

    try:
        bot.verify_method(request)
        bot.verify_chat(request)
        command = bot.verify_message(request)
        bot.run_command_by_name(command)
        return "200"
    except NotAddressedToBotRequest as ex:
        bot.info(str(ex))
        return "200"
    except NotValidBotRequest as ex:
        bot.reply(str(ex))
        return "400"
    except Exception as ex:
        bot.error(f"{str(ex)}; {traceback.print_exc()}")
        bot.reply("Sorry, a server side exception has occurred.")
        return "500"
