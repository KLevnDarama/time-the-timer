extends ColorRect

@onready var main_button: Button = $MainButton
@onready var guide: Label = $Guide
@onready var hint: Label = $Hint
@onready var ding_sound: AudioStreamPlayer = $"../DingSound"

@export var hintTime = 3500

var timeSession = 0
var timeTarget = 0
var dingDebounce = false

enum SessionState { IDLE, TIMING, RESULT }
var currentSession = SessionState.IDLE

func set_session(state: SessionState) -> SessionState:
	match state:
		SessionState.IDLE:
			guide.text = "Start counting?"
			main_button.text = "Ready"
			hint.text = "Time the Timer"
			return SessionState.IDLE
		SessionState.TIMING:
			timeSession = Time.get_ticks_msec()
			timeTarget = randi_range(5000, 7000)
			guide.text = "Count to %.2fs" % (timeTarget/1000.0)
			main_button.text = "Stop"
			return SessionState.TIMING
		SessionState.RESULT:
			var timeStopped = Time.get_ticks_msec()
			var deltaSession = timeStopped - timeSession
			var deltaTarget = timeStopped - (timeSession + timeTarget)
			guide.text = "You stopped at %.2fs" % (deltaSession/1000.0)
			main_button.text = "Retry"
			hint.text = "Offset by %.fms" % deltaTarget
			return SessionState.RESULT
		_:
			return SessionState.IDLE

func _ready() -> void:
	currentSession = set_session(SessionState.IDLE)

func _process(delta: float) -> void:
	if currentSession == SessionState.TIMING:
		var deltaHint = Time.get_ticks_msec() - timeSession
		hint.text = "%.2f" % (deltaHint/1000.0) if deltaHint <= hintTime else ""
		if deltaHint <= hintTime and deltaHint % 1000 < 100 and not dingDebounce:
			dingDebounce = true
			ding_sound.play()
		
		if deltaHint % 1000 > 100:
			dingDebounce = false

func _on_main_button_down() -> void:
	match currentSession:
		SessionState.IDLE:
			currentSession = set_session(SessionState.TIMING)
		SessionState.TIMING:
			currentSession = set_session(SessionState.RESULT)
		SessionState.RESULT:
			currentSession = set_session(SessionState.IDLE)
		_:
			currentSession = set_session(SessionState.IDLE)
	
