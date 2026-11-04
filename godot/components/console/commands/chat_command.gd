class_name ChatCommand
extends ConsoleCommand

func _init() -> void:
	commandName = "chat"
	aliases = ["say"]
	category = "General"
	description = "Allows you to send messages in world chat."
	usage = "chat [message]"
	isHidden = false # used to hide internal commands from standard help

func execute(_args: Array[String]) -> void:
	if _args.size()<1: return
	var smsg:String = ""
	for a in _args.size(): smsg += _args[a] + " "
	var content:Dictionary = {"message": smsg.strip_edges()}
	var msgAck:NakamaRTAPI.ChannelMessageAck = await Globals.serverManager.socket.write_chat_message_async(Globals.serverManager.channelWorldChat.id, content)
	if msgAck.is_exception():
				print("Error sending message: ", msgAck.get_exception().message)
				return
