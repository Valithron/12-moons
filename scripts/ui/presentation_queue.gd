class_name MoonPresentationQueue
extends Node

## Serializes semantic presentation jobs. Gameplay actions are already
## authoritative when a job is enqueued; this node only controls when the next
## visible action may begin and when input can be released.

signal busy_changed(is_busy: bool)
signal sequence_finished(label: String)

var _jobs: Array = []
var _running: bool = false
var _generation: int = 0

func enqueue(label: String, worker: Callable) -> void:
	if not worker.is_valid():
		return
	_jobs.append({"label": label, "worker": worker})
	if _running:
		return
	_running = true
	busy_changed.emit(true)
	call_deferred("_drain")

func cancel() -> void:
	_generation += 1
	_jobs.clear()
	if _running:
		_running = false
		busy_changed.emit(false)

func is_busy() -> bool:
	return _running

func pending_count() -> int:
	return _jobs.size()

func _drain() -> void:
	var local_generation := _generation
	while local_generation == _generation and not _jobs.is_empty():
		var job: Dictionary = _jobs.pop_front()
		var worker: Callable = job["worker"]
		await worker.call()
		if local_generation != _generation:
			return
		sequence_finished.emit(String(job["label"]))
	if local_generation != _generation:
		return
	_running = false
	busy_changed.emit(false)
