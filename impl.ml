module NEList : sig
  type 'a t
  val fromList : 'a list -> 'a t option
  val toList : 'a t -> 'a list
  val head : 'a t -> 'a
  val tail : 'a t -> 'a list
end = struct
  let null = function [] -> true | _ -> false

  (* Not true, but convenient simplification. *)
  let unsafe_head = List.hd
  let unsafe_tail = List.tl

  (* No extra allocation *)
  type 'a t = 'a list
  let fromList list = if null list then None else Some list
  let toList list = list
  let head = unsafe_head
  let tail = unsafe_tail
end

module BArray = struct
  (**
  Each instantiated module will work for any array as long as it has the
  same length as given here.
  *)
  module Make(Given : sig val length : int end) : sig
    module Index : sig
      type t

      (** The low bound of the index we can search upto. *)
      type lo

      (** The high bound of the index we can search upto. *)
      type hi

      val toInt : t -> int
      val initLo : lo
      val initHi : hi
      val middle : t -> t -> t
      val cmp : lo -> hi -> (unit -> 'w) -> (t -> t -> 'w) -> 'w
      val succ : t -> lo
      val pred : t -> hi
    end

    (**
    This is a 'dependent type' in the sense that it depends on the value of
    the `Given` module.
    *)
    type 'a t

    val fromArray : 'a array -> 'a t
    val get : 'a t -> Index.t -> 'a
  end = struct
    module Index = struct
      type t = int
      type lo = int
      type hi = int

      let toInt t = t
      let initLo = 0

      let initHi =
        let result = Given.length - 1 in
        (** Make sure indexing can't overflow *)
        assert (result < max_int / 2); result

      let middle lo hi = (lo + hi) / 2

      let cmp lo hi onOther onLe =
        if lo <= hi then onLe lo hi else onOther ()

      let succ = succ
      let pred = pred
    end

    type 'a t = 'a array

    let fromArray array =
      assert (Array.length array = Given.length); array

    let get = Array.unsafe_get
  end

  let binarySearch cmp (key, array) =
    let module BA = Make(struct let length = Array.length array end) in
    let array = BA.fromArray array in
    let rec look lo hi =
      BA.Index.cmp lo hi (fun () -> None) begin fun lo' hi' ->
        let m = BA.Index.middle lo' hi' in
        let x = BA.get array m in
        let cmpR = cmp (key, x) in

        if cmpR < 0 then look lo (BA.Index.pred m)
        else if cmpR = 0 then Some (BA.Index.toInt m, x)
        else look (BA.Index.succ m) hi
      end in

    look BA.Index.initLo BA.Index.initHi
end
