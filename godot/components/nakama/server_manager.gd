class_name ServerManager
extends Node

enum ReadPermissions { NO_READ, OWNER_READ, PUBLIC_READ }
enum WritePermissions { NO_WRITE, OWNER_WRITE }

const KEY:String = "getfucked"
var client:NakamaClient = Nakama.create_client(KEY, "fuckyoudie", 7350, "http")

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
  else:
    session = newSession
    #print("ID: ", session.user_id)
    #print("Username: ", session.username)

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
  var player: Handle = Globals.playerHandle
  
  # load handle from db, or create new one if no db record
  if await player.loadHandle(): 
    # Register all 'learned' commands
    Globals.consoleManager.registerCommandsBulk([CatCommand.new(), CdCommand.new(), ChatCommand.new(), \
      ConnectCommand.new(), DisconnectCommand.new(), LsCommand.new(), ScoutCommand.new()])
  else: player.newHandle(username)
   
  # setup player 
  Globals.gameNetworkManager.activateNetwork(player.rig.homeNet)
  #Globals.gameNetworkManager.connectTo("homenet")
  #player.knowledge.setup(player)
    
  # load external networks
  Globals.gameNetworkManager.loadNetworks()
    
  # connect to world chat
  connectToChat()


func connectToChat() -> void:
  var roomName = "WorldChat"
  var persistence = true
  var hidden = false
  var channelType = NakamaSocket.ChannelType.Room
  channelWorldChat = await socket.join_chat_async(roomName, channelType, persistence, hidden)

  # Nakama socket -> onChannelMessage() -> consoleManager.printChat() -> UI
  socket.received_channel_message.connect(self.onChannelMessage)
  #print("Now connected to channel id: '%s'" % [channelWorldChat.id])


func onChannelMessage(message: NakamaAPI.ApiChannelMessage) -> void:
  Globals.consoleManager.printChat("%s: %s" % [message.username, JSON.parse_string(message.content)["message"]])


func writeHandleAsync(handle: Handle) -> bool:
  #print("writeHandleAsync")

  if session == null: return false

  #print(" ...User ID = ", session.user_id)
  
  var result: NakamaAPI.ApiStorageObjectAcks = \
    await client.write_storage_objects_async(
      session,
      [NakamaWriteStorageObject.new(
        "player_data",
        "handle",
        ReadPermissions.OWNER_READ,
        WritePermissions.OWNER_WRITE,
        JSON.stringify({"handle": handle.toDict()}),"")
      ]
    )

  #print(" ...Write request completed")

  if result == null:
    push_error(" ...Null write result")
    return false

  if result.is_exception():
    push_error(" ..." + result.get_exception().message)
    return false

  #print(" ...Write acknowledgements = ", result.acks.size())

  if result.acks.is_empty():  return false

  #for ack in result.acks:
    #print(" ...Saved owner ID = ", ack.user_id)
    #print(" ...Saved collection = ", ack.collection)
    #print(" ...Saved key = ", ack.key)

  #print(" ...Starting immediate readback")
#
  #var test_result: NakamaAPI.ApiStorageObjects = \
    #await client.read_storage_objects_async(
        #session,
        #[NakamaStorageObjectId.new(
          #"player_data",
          #"handle",
          #session.user_id
        #)]
    #)
#
  #print(" ...Readback completed")
#
  #if test_result == null:
    #push_error(" ...Null readback result")
    #return false
#
  #if test_result.is_exception():
    #push_error(" ...READBACK ERROR: " + test_result.get_exception().message)
    #return false
#
  #print(" ...READBACK COUNT: ", test_result.objects.size())
#
  #for ack in result.acks:
    #print(" ...WRITE OWNER ID: ", ack.user_id)

  return true

func readHandleAsync() -> Dictionary:
  if session == null: return {}

  var storageObjects: NakamaAPI.ApiStorageObjects = await client.read_storage_objects_async(session,
    [ NakamaStorageObjectId.new("player_data", "handle", session.user_id)]
  )
  
  if storageObjects == null:
    push_error("Nakama returned a null read response.")
    return {}

  if storageObjects.is_exception():
    var exception = storageObjects.get_exception()
    push_error("Nakama read failed (%s): %s" % [ exception.status_code, exception.message ] )
    return {}

  #print("objects: ", storageObjects.objects.size())

  if storageObjects.objects.is_empty():
    push_warning("No saved handle for user: " + session.user_id)
    return {}

  var raw_value: String = storageObjects.objects[0].value
  var parsed: Variant = JSON.parse_string(raw_value)

  if not parsed is Dictionary:
    push_error("Saved data is not a valid JSON object.")
    return {}

  if not parsed.has("handle"):
    push_error("Saved data has no 'handle' field.")
    return {}

  if not parsed["handle"] is Dictionary:
    push_error("Saved handle is not a dictionary.")
    return {}

  #print("Handle data loaded")
  return parsed["handle"]
