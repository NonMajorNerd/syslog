class_name ServerManager
extends Node

const KEY:String = "Us5TCowYSVXi7DXA"

var _session:NakamaSession
var _client := Nakama.create_client(KEY, "192.168.1.109", 7350, "http")

var errorMessage:String = "NOERROR" # the most recent error message

func authenticate_async(user:String, email:String, password:String, register:bool=false) -> int:
	var result := OK
	if not email: email = ""
	print("!! AUTH ASYNC !! " + str(email))
	var newSession:NakamaSession = await _client.authenticate_email_async(email, password, user, register)
	if newSession.is_exception():
		result = newSession.get_exception().status_code as Error
		errorMessage = newSession.get_exception().message
	else: _session = newSession
		
	return result
