class_name ServerManager
extends Node

const KEY:String = "getfucked"
var client:NakamaClient = Nakama.create_client(KEY, "fuckyoudie", 7350, "http")

var session:NakamaSession #session.AuthToken #session.RefreshToken
var socket:NakamaSocket # client.NewSocket();
var channelWorldChat: NakamaRTAPI.Channel

var errorMessage:String = "NOERROR" # the most recent error message

# attempt to authenticate and start a session
func authenticate_async(user:String, email:String, password:String, register:bool=false) -> int:
	var result := OK
	if not email: email = ""
	
	var newSession:NakamaSession = await client.authenticate_email_async(email, password, user, register)
	if newSession.is_exception():
		result = newSession.get_exception().status_code as Error
		errorMessage = newSession.get_exception().message
	else: session = newSession
		
	return result
		
# once authenticated, attempt to open a socket
func connectSocket() -> int:
	var result := OK
	
	socket = Nakama.create_socket_from(client)
	var connected : NakamaAsyncResult = await socket.connect_async(session)
	if connected.is_exception():
		result = connected.get_exception().status_code as Error
		errorMessage = connected.get_exception().message
	
	return result
	
# create the world ID match if it doesnt already exist
#func createWorld() -> int:
	#var result:=OK
	#var createdMatch = await socket.create_match_async(WORLD_ID)
	#if createdMatch.is_exception():
		#result = createdMatch.get_exception().status_code as Error
		#errorMessage = createdMatch.get_exception().message 
	#
	#return result

# join the world ID match
#func joinWorld() -> int:
	#var result:=OK
	#var joinedMatch = await socket.join_match_async(WORLD_ID)
	#if joinedMatch.is_exception():
		#result = joinedMatch.get_exception().status_code as Error
		#errorMessage = joinedMatch.get_exception().message 
	#
	#return result

func connectToWorld(un:String) -> void:
	# this should probably get moved to main
	# gets called by signon command currently
	
	Globals.playerHandle.loadHandle(un)
	Globals.gameNetworkManager.activeNetwork = Globals.playerHandle.rig.homeNet
	
	#joinWorld()
	connectToChat()
	
	#if first time connecting:
	Globals.consoleManager.registerCommandsBulk([catCommand.new(), ChatCommand.new(), cdCommand.new(), lsCommand.new(), scoutCommand.new()])
	#Globals.consoleManager.registerCommand(catCommand.new())
	#Globals.consoleManager.registerCommand(cdCommand.new())
	#Globals.consoleManager.registerCommand(lsCommand.new())
	#Globals.consoleManager.registerCommand(scoutCommand.new())
	
func connectToChat() -> void:
	var roomname = "WorldChat"
	var persistence = true
	var hidden = false
	var type = NakamaSocket.ChannelType.Room
	channelWorldChat = await socket.join_chat_async(roomname, type, persistence, hidden)
	
	socket.received_channel_message.connect(self._on_channel_message)
	print("Now connected to channel id: '%s'" % [channelWorldChat.id])

func _on_channel_message(pMessage : NakamaAPI.ApiChannelMessage):
	Globals.consoleManager.printChat("%s: %s" % [pMessage.username, JSON.parse_string(pMessage.content)["message"]])
