class_name ChatCommand
extends ConsoleCommand

func _init() -> void:
  commandName = "chat"
  aliases = ["say"]
  category = "General"
  description = "Send a message to world chat."
  arguments = [CommandSpec.argument("message", TYPE_STRING, true, null, "Message to send.", [], null, null, true)]

func execute(input: CommandInput) -> void:
  if Globals.serverManager.channelWorldChat == null or Globals.serverManager.socket == null:
    Globals.consoleManager.printOutput("World chat is unavailable.", Globals.colors["CONSOLE"]["FONT_FAILURE"])
    return
  var content: Dictionary = {"message": input.getString("message").replace("[", "[lb]").replace("]", "[rb]")}
  var response: NakamaRTAPI.ChannelMessageAck = await Globals.serverManager.socket.write_chat_message_async(Globals.serverManager.channelWorldChat.id, content)
  if response.is_exception():
    Globals.consoleManager.printOutput("Chat failed: " + response.get_exception().message, Globals.colors["CONSOLE"]["FONT_FAILURE"])
