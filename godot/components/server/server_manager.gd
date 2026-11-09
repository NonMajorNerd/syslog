class_name ServerManager
extends Node

#const KEY:String = "getfucked"
#var client:NakamaClient = Nakama.create_client(KEY, "fuckyoudie", 7350, "http")

var session: NakamaSession
var socket: NakamaSocket
var channelWorldChat: NakamaRTAPI.Channel

var errorMessage: String = "NOERROR" # the most recent error message

# RegisterCommand and SignonCommand await this Nakama authentication result.
func authenticateAsync(user: String, email: String, password: String, register: bool=false) -> int:
  var result := OK
  if not email: email = ""

  var newSession: NakamaSession = await client.authenticate_email_async(email, password, user, register)
  if newSession.is_exception():
    result = newSession.get_exception().status_code as Error
    errorMessage = newSession.get_exception().message
  else: session = newSession

  return result

# Authentication creates an HTTP session; real-time chat needs a separate socket.
func connectSocket() -> int:
  var result := OK

  socket = Nakama.create_socket_from(client)
  var connected : NakamaAsyncResult = await socket.connect_async(session)
  if connected.is_exception():
    result = connected.get_exception().status_code as Error
    errorMessage = connected.get_exception().message

  return result

# SignonCommand calls this after authentication and socket connection.
func connectToWorld(username: String) -> void:

  # Restore progress and homenet
  Globals.playerHandle.loadHandle(username)
  Globals.gameNetworkManager.activateNetwork(Globals.playerHandle.rig.homeNet)
  
  connectToChat()

  # Register default commands
  Globals.consoleManager.registerCommandsBulk([CatCommand.new(), ChatCommand.new(), \
    CdCommand.new(), LsCommand.new(), ScoutCommand.new()])

func connectToChat() -> void:
  var roomName = "WorldChat"
  var persistence = true
  var hidden = false
  var channelType = NakamaSocket.ChannelType.Room
  channelWorldChat = await socket.join_chat_async(roomName, channelType, persistence, hidden)

  # Nakama socket -> onChannelMessage() -> consoleManager.printChat() -> UI
  socket.received_channel_message.connect(self.onChannelMessage)
  print("Now connected to channel id: '%s'" % [channelWorldChat.id])

func onChannelMessage(message: NakamaAPI.ApiChannelMessage) -> void:
  Globals.consoleManager.printChat("%s: %s" % [message.username, JSON.parse_string(message.content)["message"]])
