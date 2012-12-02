(** A failure occured. *)
exception Failure
(** A failure occured (with given explanation). *)
exception Failure_msg of string
exception Timeout
(** Trying to read data from a stream which has ended. *)
exception End_of_stream

(** Initialize GStreamer. This function should be called before anything
    other GStreamer function. *)
val init : ?argv:(string array) -> unit -> unit

(** Uninitialize GStreamer. This function does not normally need to be called
    excepting when debugging memory. *)
val deinit : unit -> unit

(** Version of GStreamer. *)
val version : unit -> int * int * int * int

(** Version of GStreamer. *)
val version_string : unit -> string

(** Type for data in buffers. *)
type data = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

(** Formats for durations. *)
module Format : sig
  (** Format for durations. *)
  type t =
  | Undefined
  | Default
  | Bytes
  | Time (** Time in nanoseconds. *)
  | Buffers
  | Percent

  (** String representation of a duration format. *)
  val to_string : t -> string
end

(** Events. *)
module Event : sig
  (** Seek mode. *)
  type seek_flag =
  | Seek_flag_none
  | Seek_flag_flush
  | Seek_flag_accurate
  | Seek_flag_key_unit
  | Seek_flag_segment
  | Seek_flag_skip
  | Seek_flag_snap_before
  | Seek_flag_snap_after
  | Seek_flag_snap_nearest
end

(** Elements. *)
module Element : sig
  (** An element. *)
  type t

  val set_property_string : t -> string -> string -> unit

  val set_property_int : t -> string -> string -> unit

  val set_property_bool : t -> string -> string -> unit

  (** State of an element. *)
  type state =
  | State_void_pending
  | State_null
  | State_ready
  | State_paused
  | State_playing

  (** String representation of a state. *)
  val string_of_state : state -> string

  (** Return value for state change. *)
  type state_change =
  | State_change_sucess
  | State_change_async
  | State_change_no_preroll

  val set_state : t -> state -> state_change

  (** Current state of an element: return value, current state and pending state. *)
  val get_state : t -> state_change * state * state

  (** Link two elements. *)
  val link : t -> t -> unit

  (** Sequentially link a list of element. *)
  val link_many : t list -> unit

  (** Current position of an element. *)
  val position : t -> Format.t -> Int64.t

  (** Seek to a given position relative to the start of the stream. *)
  val seek_simple : t -> Format.t -> Event.seek_flag list -> Int64.t -> unit
end

(** Element factories. *)
module Element_factory : sig
  type t = Element.t

  val make : string -> string -> t
end

(** Messages. *)
module Message : sig
  type message_type =
  | Error
  | Tag
  | State_changed
  | Stream_status
  | Duration_changed
  | Async_done
  | Stream_start

  type t

  val message_type : t -> message_type

  val source_name : t -> string

  val parse_tag : t -> (string * string list) list
end

(** Buses. *)
module Bus : sig
  type t

  val of_element : Element.t -> t

  val pop_filtered : t -> Message.message_type list -> Message.t option

  val timed_pop_filtered : t -> Message.message_type list -> Message.t
end

(** Bins. *)
module Bin : sig
  type t = Element.t

  val of_element : Element.t -> t

  val add : t -> Element.t -> unit

  val add_many : t -> Element.t list -> unit

  (** [get_by_name "foo"] find a bin by name. Raises [Not_found] if element does
      not exist. *)
  val get_by_name : t -> string -> Element.t
end

(** Pipelines. *)
module Pipeline : sig
  type t = Element.t

  val create : string -> t

  (** Create a pipeline from a string description. *)
  val parse_launch : string -> t
end

(** Buffers. *)
module Buffer : sig
  (** A buffer. *)
  type t

  (** Create a buffer containing a given string as contents. *)
  val of_string : string -> int -> int -> t

  (** Create a buffer containing given data as contents. *)
  val of_data : data -> int -> int -> t

  (** Set the presentation time of a buffer. *)
  val set_presentation_time : t -> Int64.t -> unit

  (** Set the decoding time of a buffer. *)
  val set_decoding_time : t -> Int64.t -> unit

  (** Set the duration of a buffer. *)
  val set_duration : t -> Int64.t -> unit
end

(** App sources. *)
module App_src : sig
  type t

  val to_element : t -> Element.t

  val of_element : Element.t -> t

  (** Push a buffer. *)
  val push_buffer : t -> Buffer.t -> unit

  (** Push a buffer in string format. *)
  val push_buffer_string : t -> string -> unit

  (** Register a callback that will be called when data need to be fed into the
      source (the argument is the number of bytes needed by the source). *)
  val on_need_data : t -> (int -> unit) -> unit

  (** Emit an end of stream signal. *)
  val end_of_stream : t -> unit

  val set_format : t -> Format.t -> unit
end

(** App sinks. *)
module App_sink : sig
  type t

  val of_element : Element.t -> t

  (** Pull a buffer in data format. *)
  val pull_buffer_data : t -> data

  (** Pull a buffer in string format. *)
  val pull_buffer_string : t -> string

  (** Enable signal emitting. *)
  val emit_signals : t -> unit

  (** Check whether the end of stream was reached. *)
  val is_eos : t -> bool

  (** Register a callback which will be called whenever a sample (a buffer in
      GStreamer terminology) is available. [emit_signals] should be called first
      in order for the callback to be called. *)
  val on_new_sample : t -> (unit -> unit) -> unit

  (** Set the maximal number of internal buffers. *)
  val set_max_buffers : t -> int -> unit
end

(** Capabilities. *)
module Caps : sig
  type t

  val to_string : t -> string
end

(** Type finders. *)
module Type_find_element : sig
  type t

  val of_element : Element.t -> t

  val on_have_type : t -> (int -> Caps.t -> unit) -> unit
end

(** Tag setters. *)
module Tag_setter : sig
  type t

  type merge_mode =
  | Undefined
  | Replace_all
  | Replace
  | Append
  | Prepend
  | Keep
  | Keep_all
  | Count

  val of_element : Element.t -> t

  (** Set a tag in an element. *)
  val add_tag : t -> merge_mode -> string -> string -> unit
end
