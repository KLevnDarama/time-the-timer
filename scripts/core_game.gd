extends VBoxContainer

@onready var tick_sound: AudioStreamPlayer = $TickSound
@onready var main_label: Label = $MainLabel
@onready var main_button: Button = $ButtonContainer/MainButton
@onready var hint_label: Label = $HintLabel

var hintTime = 3500
var timeSession = 0
var timeTarget = 0
var tickDebounce = false

enum SessionState { IDLE, TIMING, RESULT }
var currentSession = SessionState.IDLE

func set_session(state: SessionState) -> SessionState:
	match state:
		SessionState.IDLE:
			main_label.text = "Start counting?"
			main_button.text = "Ready"
			hint_label.text = "Time the Timer"
			return SessionState.IDLE
		SessionState.TIMING:
			timeSession = Time.get_ticks_msec()
			timeTarget = randi_range(500, 700) * 10
			main_label.text = "Count to %.2fs" % (timeTarget/1000.0)
			main_button.text = "Stop"
			return SessionState.TIMING
		SessionState.RESULT:
			var timeStopped = Time.get_ticks_msec()
			var deltaSession = timeStopped - timeSession
			var deltaTarget = timeStopped - (timeSession + timeTarget)
			main_label.text = "You stopped at %.2fs" % (deltaSession/1000.0)
			main_button.text = "Retry"
			hint_label.modulate.a = 1
			if deltaTarget < 0:
				hint_label.text = "Early by %.fms" % abs(deltaTarget)
			elif deltaTarget > 0:
				hint_label.text = "Late by %.fms" % deltaTarget
			else:
				hint_label.text = "Perfect timing"
			return SessionState.RESULT
		_:
			return SessionState.IDLE

func set_input() -> void:
	match currentSession:
		SessionState.IDLE:
			currentSession = set_session(SessionState.TIMING)
		SessionState.TIMING:
			currentSession = set_session(SessionState.RESULT)
		SessionState.RESULT:
			currentSession = set_session(SessionState.IDLE)
		_:
			currentSession = set_session(SessionState.IDLE)

func _ready() -> void:
	currentSession = set_session(SessionState.IDLE)

func _process(_delta: float) -> void:
	if currentSession == SessionState.TIMING:
		var deltaHint = Time.get_ticks_msec() - timeSession
		tick_sound.volume_db = remap(deltaHint,0,hintTime,0,-30)
		hint_label.modulate.a = remap(deltaHint,0,hintTime,1,0)
		hint_label.text = "%.2f" % (deltaHint/1000.0) if deltaHint <= hintTime else ""
		if deltaHint <= hintTime and deltaHint % 1000 < 100 and not tickDebounce:
			tickDebounce = true
			tick_sound.play()
		
		if deltaHint % 1000 > 100:
			tickDebounce = false

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_accept"):
		#set_input()

func _on_main_button_down() -> void:
	set_input()
