theory PathInvariant
imports PathRel
begin

lemma mono_list :
  "push_popL (map snd lst) \<Longrightarrow>
   pathR (mono_rules iv) lst \<Longrightarrow>
   length lst > 0 \<Longrightarrow>
   monoI iv (hd lst) \<Longrightarrow>
   monoI iv (last lst)"
apply (induction "mono_rules iv" lst rule:pathR.induct)
apply (auto simp add:pathR.simps mono_works pathR2 pathR3 push_popL_def)
done

(* top rules *)
(* actually, the mono rules will hold *)
(* but sometime mono push and pop will only hold because
   they are part of call sequences
 *)

(*
mono_pop : because it is a call, and calls have the invariant

this rule has to be proven for each possible call into a contract
for the invariant to hold ...
*)
definition call_rule :: "('a \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) list \<Rightarrow> bool" where
"call_rule iv lst = (
  call (map snd lst) \<longrightarrow> iv (fst (hd lst)) \<longrightarrow>
  iv (fst (last lst))
)"

definition call_out :: "'a list list \<Rightarrow> bool" where
"call_out lst = (
  push_popL lst \<and>
  length lst > 1 \<and>
  (last lst, hd lst) \<in> tlR \<and>
  (\<forall>x \<in> set lst. length x \<ge> length (hd lst))
)"

(*
for pushing, we need to ... well in theory the external call
 could break the invariant and then fix it
*)
definition call_out_rule :: "('a \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) list \<Rightarrow> bool" where
"call_out_rule iv lst = (
  call_out (map snd lst) \<longrightarrow> iv (fst (hd lst)) \<longrightarrow>
  iv (fst (last lst))
)"

lemma mono_same_length :
   "(a,b) \<in> mono_same iv \<Longrightarrow>
    length (snd a) = length (snd b)"
  by (smt fst_conv mem_Collect_eq mono_same_def snd_conv)


lemma mono_pop_length :
   "(a,b) \<in> mono_pop iv \<Longrightarrow>
    length (snd a) = length (snd b) + 1"
  by (smt Suc_eq_plus1 fst_conv length_Cons mem_Collect_eq mono_pop_def snd_conv)

lemma mono_push_length :
   "(a,b) \<in> mono_push iv \<Longrightarrow>
    length (snd a) + 1 = length (snd b)"
  by (smt Int_iff One_nat_def add.right_neutral add_Suc_right fst_conv length_Cons mem_Collect_eq mono_push_def prod.sel(2))

lemma mono_is_push :
  "(a,b) \<in> mono_rules iv \<Longrightarrow>
   length (snd a) + 1 = length (snd b) \<Longrightarrow>
   (a, b) \<in> mono_push iv"
by (metis UnE less_add_same_cancel1 mono_pop_length mono_rules_def mono_same_length not_add_less1 zero_less_one)

lemma mono_is_pop :
  "(a,b) \<in> mono_rules iv \<Longrightarrow>
   length (snd a) = length (snd b) + 1 \<Longrightarrow>
   (a, b) \<in> mono_pop iv"
  by (metis UnE less_add_same_cancel1 mono_push_length mono_rules_def mono_same_length not_add_less1 zero_less_one)

lemma mono_is_same :
  "(a,b) \<in> mono_rules iv \<Longrightarrow>
   length (snd a) = length (snd b) \<Longrightarrow>
   (a, b) \<in> mono_same iv"
  by (metis UnE less_add_same_cancel1 mono_pop_length mono_push_length mono_rules_def not_add_less1 zero_less_one)

(* first the invariant is pushed into stack (second element). *)
lemma call_invariant_push :
  "call (map snd lst) \<Longrightarrow>
   monoI iv (hd lst) \<Longrightarrow>
   pathR (mono_rules iv) lst \<Longrightarrow>
   iv (fst (hd lst)) \<Longrightarrow>
   iv (hd (snd (lst!1)))"
apply (auto simp add:path_defs path_def
  call_def tlR_def)
apply (subgoal_tac "hd lst = lst!0")
apply auto
defer
  apply (metis hd_conv_nth list.size(3) not_numeral_less_zero)
apply (subgoal_tac "(lst!0, lst!1) \<in> mono_push iv")
apply (auto simp add:mono_push_def)[1]
apply (subgoal_tac "(lst!0, lst!1) \<in> mono_rules iv")
defer
  apply simp
apply (subgoal_tac "length (snd (lst!0)) + 1 = length (snd (lst!1))")
using mono_is_push [of "lst!0" "lst!1" iv]
  apply blast
  by (metis One_nat_def less_imp_Suc_add list.size(4) nth_map zero_less_Suc)

(* pushed element cannot change *)
lemma call_invariant_before_after :
  "call lst \<Longrightarrow>
   lst!1 = lst!(length lst-2)"
apply (subgoal_tac "length (lst!1) = length (lst!(length lst-2))")
using call_inside_big_idx [of lst "length lst-2"]
  apply (metis One_nat_def PathRel.take_all Suc_1 Suc_leI Suc_lessD call_def diff_less_mono2 lessI zero_less_diff)
using call_ncall [of lst]
  by (smt One_nat_def Suc_leI Suc_lessD call_def diff_less last_clip le_less length_map ncall_last nth_map numeral_2_eq_2 zero_less_diff zero_less_numeral)

lemma get_mono_inv :
  "monoI iv a \<Longrightarrow>
   length (snd a) > 0 \<Longrightarrow>
   iv (hd (snd a)) \<Longrightarrow>
   iv (fst a)"
  using hd_conv_nth monoI_def by fastforce

lemma ncall_first_step : 
  "ncall lst \<Longrightarrow>
   lst!1 = lst!0 + 1"
by (simp add:ncall_def sucR_def)

lemma ncall_next : 
  "ncall lst \<Longrightarrow>
   lst ! (length lst - 2) = lst!1"
  by (smt One_nat_def Suc_diff_Suc Suc_lessI diff_le_self last_clip less_eq_Suc_le ncall_def ncall_last numeral_2_eq_2 zero_less_diff)

lemma ncall_last_length : 
  "ncall lst \<Longrightarrow>
   last lst + 1 = lst ! (length lst - 2)"
using ncall_stack_length ncall_next ncall_first_step
  by (metis gr_implies_not_zero hd_conv_nth list.size(3) ncall_def)

lemma call_last_length : 
  "call lst \<Longrightarrow>
   length (last lst) + 1 =
   length (lst ! (length lst - 2))"
using ncall_stack_length call_ncall
  by (smt One_nat_def call_def diff_less last_index length_map ncall_last_length nth_map numeral_2_eq_2 order.strict_trans zero_less_Suc)


(* because the pushed element didn't change, current must have the
   invariant, and we can use the mono push rule *)
lemma call_mono_invariant :
  "call (map snd lst) \<Longrightarrow>
   monoI iv (hd lst) \<Longrightarrow>
   pathR (mono_rules iv) lst \<Longrightarrow>
   iv (fst (hd lst)) \<Longrightarrow>
   iv (fst (last lst))"
apply (subgoal_tac "monoI iv (lst ! (length lst-2))")
apply (subgoal_tac "iv (hd (snd (lst ! (length lst-2))))")
apply (subgoal_tac "(lst ! (length lst-2), last lst) \<in> mono_pop iv")
apply (subgoal_tac "iv (fst (lst ! (length lst-2)))")
  apply (smt fst_conv list.sel(1) mem_Collect_eq mono_pop_def snd_conv)
  apply (metis (no_types, hide_lams) Suc_eq_plus1 hd_conv_nth length_Cons list.sel(1) list.size(3) monoI_def mono_pop_length nat.simps(3) zero_less_Suc)
apply (subgoal_tac "(lst ! (length lst - 2), last lst) \<in> mono_rules iv")
apply (subgoal_tac "length (snd (last lst)) + 1 = length (snd (lst ! (length lst - 2)))")
  apply (smt UnE add_right_imp_eq mono_push_length mono_rules_def mono_same_length numeral_eq_iff numeral_plus_numeral numerals(1) semiring_norm(2) semiring_norm(6) semiring_norm(85) semiring_norm(87) semiring_normalization_rules(24) semiring_normalization_rules(25))
using call_last_length [of "map snd lst"]
apply simp
apply (subgoal_tac "lst \<noteq> []")
apply (simp add:last_map)
  using call_def apply force
apply (subgoal_tac "lst \<noteq> []")
apply (simp add:path_defs path_def last_conv_nth)
  apply (smt Nil_is_map_conv Nitpick.size_list_simp(2) One_nat_def Suc_diff_Suc call_def diff_less length_greater_0_conv length_tl less_trans_Suc map_tl not_less_less_Suc_eq numeral_2_eq_2 zero_less_numeral)
  using call_def apply force
apply (subgoal_tac "snd (lst ! 1) = snd (lst ! (length (map snd lst) - 2))")
using call_invariant_push [of lst iv]
apply simp
using call_invariant_before_after [of "map snd lst"]
apply simp
  apply (smt Nil_is_map_conv One_nat_def call_def diff_less length_greater_0_conv length_tl less_trans_Suc map_tl nth_map order.strict_trans zero_less_diff zero_less_numeral)
using mono_list [of "take (length lst - 1) lst" iv]
apply (auto simp add:call_def push_popL_def)
apply (subgoal_tac "lst \<noteq> []")
apply auto
apply (subgoal_tac
   "map snd (take (length lst - 1) lst) =
    take (length lst - 1) (map snd lst)")
defer
apply (simp add: take_map)
apply (auto simp add:pathR_take)
  by (metis One_nat_def Suc_1 Suc_diff_Suc Suc_lessD diff_Suc_less hd_take last_take)

lemma call_first_prev :
"call_end lst (last lst) \<Longrightarrow>
 last (take (length lst - Suc 0) lst) = lst!0"
  by (smt Nitpick.size_list_simp(2) One_nat_def Suc_diff_Suc call_end_def diff_Suc_Suc diff_less first_one_smaller_prev last_take length_tl less_numeral_extra(2) zero_less_Suc)

lemma decompose_call_end :
  "call_end lst (last lst) \<Longrightarrow>
   x \<in> set (indexSplit (findIndices (take (length lst-1) lst) (lst!0))
             (take (length lst-1) lst)) \<Longrightarrow>
   call_end x (lst!0) \<or> const_seq x (lst!0)"
using correct_pieces [of "take (length lst-1) lst" x]
apply simp
apply (subgoal_tac "inc_decL (take (length lst - 1) lst)")
defer
apply (simp add:pathR_take call_end_def inc_decL_def)
apply simp
apply (subgoal_tac "lst \<noteq> [] \<and> 1 < length lst")
defer
apply (simp add:call_end_def)
  using less_nat_zero_code apply auto[1]
apply clarsimp
apply (subgoal_tac "hd (take (length lst - Suc 0) lst) = lst!0")
defer
  apply (simp add: hd_conv_nth)
apply simp
apply (subgoal_tac "last (take (length lst - Suc 0) lst) = lst!0")
defer
using call_first_prev apply fastforce
apply (simp add:split_def)
  by (metis One_nat_def call_end_def first_smaller1 first_smaller_before)

lemma decompose_call_end_index :
  "call_end lst (last lst) \<Longrightarrow>
   \<exists>ilst. (\<forall>x \<in> set (indexSplit ilst (take (length lst-1) lst)).
   call_end x (lst!0) \<or> const_seq x (lst!0))"
apply (rule exI[where x =
   "findIndices (take (length lst-1) lst) (lst!0)"])
using decompose_call_end apply fastforce
done

lemma call_e_end :
"call_e lst (last lst) \<Longrightarrow>
 call_end (map length lst) (last (map length lst))"
  using call_end1 call_end_last by fastforce

lemma call_e_pathR:
"call_e lst (last lst) \<Longrightarrow> pathR push_pop lst"
by (simp add:call_e_def push_popL_def)

(*
lemma call_end_inside_big_idx :
"call_end lst (last lst) \<Longrightarrow>
 j < length lst - 1 \<Longrightarrow>
 lst ! 0 \<le> lst ! j"
*)

lemma call_end_inside_big :
"call_end lst (last lst) \<Longrightarrow>
 x \<in> set (take (length lst - 1) lst) \<Longrightarrow>
 lst ! 0 \<le> x"
using first_smaller1 [of "lst" "length lst - 1"]
using first_smaller_before [of "length lst -1" "lst" x]
by (auto simp add:call_end_def sucR_def)

lemma call_e_inside_big_idx :
"call_e lst (last lst) \<Longrightarrow>
 j < length lst - 1 \<Longrightarrow>
 takeLast (length (lst!0)) (lst!j) = lst ! 0"
using stack_unchanged [of "take (Suc j) lst"
   "length (lst!0)"]
apply simp
apply (cases "push_popL (take (Suc j) lst)")
defer
apply (simp add:call_e_def push_popL_def pathR_take)
apply (cases "take (Suc j) lst = []")
apply (simp add:clip_def call_e_def)

apply (simp add:last_take hd_take)
apply (subgoal_tac "\<forall>sti\<in>set (take (Suc j)lst).
        length (lst ! 0) \<le> length sti")
apply auto
  apply (simp add: hd_conv_nth)

subgoal for sti
using call_end_inside_big [of "map length lst" "length sti"]
apply (simp add:call_e_end)
apply (cases "length sti
     \<in> set (take (length (map length lst) - 1) (map length lst))")
apply auto
  apply (simp add: clip_def drop_map take_map)
  by (meson Suc_leI image_eqI set_take_subset_set_take subset_code(1))
done

lemma call_e_inside_big :
 "call_e lst (last lst) \<Longrightarrow>
  a \<in> set (take (length lst - 1) lst) \<Longrightarrow>
  takeLast (length (lst ! 0)) a = lst ! 0"
using ex_idx [of a "take (length lst - 1) lst"]
by (auto simp add: call_e_inside_big_idx)

(* decompose call_e into smaller pieces ... should follow from
   above similarly to call decomposition *)
lemma decompose_call_e_index :
  "call_e lst (last lst) \<Longrightarrow>
   \<exists>ilst. (\<forall>x \<in> set (indexSplit ilst (take (length lst-1) lst)).
   call_e x (lst!0) \<or> const_seq x (lst!0))"
using decompose_call_end_index [of "map length lst"]
      call_e_end [of lst]
apply auto
subgoal for ilst
apply (rule exI[where x=ilst])
apply clarsimp
(* because internally the stack is high,
   it should not change *)
apply (case_tac "const_seq (map length x) (map length lst ! 0) \<or>
    call_end (map length x) (map length lst ! 0)")
defer
subgoal for x
using index_split_map [of x ilst "take (length lst - 1) lst" length]
apply (simp add:take_map drop_map)
apply force
done
subgoal for x
using pathR_split [of "push_pop"
   "take (length lst - 1) lst" x ilst]
  pathR_take [of "push_pop" lst "length lst-1"]
  call_e_pathR [of lst]
apply simp

apply auto
subgoal (* constant *)
using const_seq_convert [of x "map length lst ! 0"]
apply (auto simp add:push_popL_def)
apply (cases x)
using const_seq_empty apply force
subgoal for xa a list
apply (simp add:map_nth)
using const_seq_eq [of a list xa]
apply simp
apply (subgoal_tac "a \<in> set (take (length lst - 1) lst)")
defer
using in_index_split apply fastforce
apply (subgoal_tac "lst ! 0 = a")
apply auto

using call_e_inside_big [of lst a]
  by (metis One_nat_def PathRel.take_all const_seq_eq length_greater_0_conv length_pos_if_in_set nth_map take_eq_Nil)
done
apply (rule call_end2)
  apply (clarsimp simp add: call_e_def)
  apply (metis Suc_lessD nth_map)

  using push_popL_def apply blast
using call_end_last [of "map length x" "length (lst ! 0)"]
using call_e_inside_big [of lst "last x"]
apply simp
apply (subgoal_tac "map length lst ! 0 = length (lst!0)")
defer
apply (simp add:call_e_def)
  using Suc_lessD nth_map apply blast
apply simp
apply (subgoal_tac "last x \<in> set (take (length lst - 1) lst)")
defer
apply (rule in_index_split [of x ilst "take (length lst-1) lst"
  "last x"])
apply auto
apply (simp add:call_end_def)
  apply (metis One_nat_def Suc_lessD diff_Suc_less gr_implies_not_zero in_set_conv_nth last_conv_nth length_0_conv)
apply (subgoal_tac "length (last x) = length (lst!0)")
  apply (metis PathRel.take_all)
apply (simp add:call_end_def)
  by (metis Suc_lessD last_map length_greater_0_conv)
done done

lemma decompose_call_e :
  "call_e lst (last lst) \<Longrightarrow>
  ilst = findIndices
             (take (length lst - Suc 0)
               (map length lst))
             (map length lst ! 0) \<Longrightarrow>
   x \<in> set (indexSplit ilst (take (length lst-1) lst)) \<Longrightarrow>
   call_e x (lst!0) \<or> const_seq x (lst!0)"
using decompose_call_end [of "map length lst" "map length x"]
      call_e_end [of lst]
apply auto
apply (case_tac "const_seq (map length x) (map length lst ! 0) \<or>
    call_end (map length x) (map length lst ! 0)")
defer
using index_split_map [of x ilst "take (length lst - 1) lst" length]
apply (simp add:take_map drop_map)
using pathR_split [of "push_pop"
   "take (length lst - 1) lst" x ilst]
  pathR_take [of "push_pop" lst "length lst-1"]
  call_e_pathR [of lst]
apply simp

apply auto
subgoal (* constant *)
using const_seq_convert [of x "map length lst ! 0"]
apply (auto simp add:push_popL_def)
apply (cases x)
using const_seq_empty apply force
subgoal for xa a list
apply (simp add:map_nth)
using const_seq_eq [of a list xa]
apply simp
apply (subgoal_tac "a \<in> set (take (length lst - 1) lst)")
defer
using in_index_split apply fastforce
apply (subgoal_tac "lst ! 0 = a")
apply auto

using call_e_inside_big [of lst a]
  by (metis One_nat_def PathRel.take_all const_seq_eq length_greater_0_conv length_pos_if_in_set nth_map take_eq_Nil)
done
apply (rule call_end2)
  apply (clarsimp simp add: call_e_def)
  apply (metis Suc_lessD nth_map)

  using push_popL_def apply blast
using call_end_last [of "map length x" "length (lst ! 0)"]
using call_e_inside_big [of lst "last x"]
apply simp
apply (subgoal_tac "map length lst ! 0 = length (lst!0)")
defer
apply (simp add:call_e_def)
  using Suc_lessD nth_map apply blast
apply simp
apply (subgoal_tac "last x \<in> set (take (length lst - 1) lst)")
defer
apply (rule in_index_split [of x ilst "take (length lst-1) lst"
  "last x"])
apply auto
apply (simp add:call_end_def)
  apply (metis One_nat_def Suc_lessD diff_Suc_less gr_implies_not_zero in_set_conv_nth last_conv_nth length_0_conv)
apply (subgoal_tac "length (last x) = length (lst!0)")
  apply (metis PathRel.take_all)
apply (simp add:call_end_def)
by (metis Suc_lessD last_map length_greater_0_conv)


definition psublists :: "'a list \<Rightarrow> 'a list set" where
"psublists lst = {take l (drop i lst) | l i. l < length lst}"

definition callout_rel :: "('a * 'a list \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> ('a * 'a list) rel" where
"callout_rel iv level =
    {(a,b) | a b. length (snd a) = level \<and> length (snd b) = level + 1 \<and> (iv a \<longrightarrow> iv b) }
  \<union> {(a,b) | a b. length (snd a) \<noteq> level \<or> length (snd b) \<noteq> level + 1}"

definition split_no_empty :: "nat list \<Rightarrow> 'a list \<Rightarrow> 'a list list" where
"split_no_empty ilst lst = filter (%lst. lst \<noteq> []) (indexSplit ilst lst)"

lemma concat_filter : "concat (filter (%lst. lst \<noteq> []) lst) = concat lst"
by (induction lst; auto)

definition pieces :: "'a list list \<Rightarrow> 'a list list list" where
"pieces lst =
  split_no_empty
     (findIndices (take (length lst - 1) (map length lst))
             (map length lst ! 0)) (take (length lst-1) lst)"

lemma call_e_from_pieces :
  "call_e lst x \<Longrightarrow>
   concat (pieces lst) = take (length lst-1) lst"
apply (simp add:call_e_def pieces_def split_no_empty_def
  concat_filter)
using split_and_combine2 [of "findIndices
         (take (length lst - Suc 0)
           (map length lst))
         (map length lst ! 0)" "take (length lst-1) lst"]
  by simp

lemma call_e_has_pieces :
  "call_e lst x \<Longrightarrow> length (pieces lst) > 0"
apply (cases "length (concat (pieces lst)) = 0")
using call_e_from_pieces [of lst x]
apply (auto simp add:call_e_def)
  by (metis diff_is_0_eq not_less take_eq_Nil)

lemma decompose_call_e_no_empty :
  "call_e lst (last lst) \<Longrightarrow>
   x \<in> set (pieces lst) \<Longrightarrow>
   call_e x (lst!0) \<or> const_seq x (lst!0)"
using decompose_call_e [of lst
   "(findIndices (take (length lst - 1) (map length lst)) (map length lst ! 0))" x]
by (auto simp:split_no_empty_def pieces_def)

lemma call_e_final : "call_e lst x \<Longrightarrow> last lst = x"
apply (auto simp add : call_e_def first_return_def first_def tlR_def)
  by (metis One_nat_def Suc_lessD last_conv_nth length_greater_0_conv)

lemma no_empty_pieces : "[] \<notin> set (pieces lst)"
by (simp add: pieces_def split_no_empty_def)

lemma piece_last :
   "call_e lst (last lst) \<Longrightarrow>
    b \<in> set (pieces lst) \<Longrightarrow>
    last b = lst!0"
using decompose_call_e_no_empty [of lst b]
apply auto
using call_e_final apply force
apply (cases "b = []")
using no_empty_pieces apply fastforce
apply (simp add:const_seq_def)
  using last_in_set by blast

lemma drop_concat_aux :
 "b \<noteq> [] \<Longrightarrow>
  lst = concat (a#b#rest) @ [x] \<Longrightarrow>
  last b # concat rest @ [x] =
    drop (length a + length b - 1) lst"
apply (subgoal_tac "drop (length a + length b - Suc 0) a = []")
apply (auto)
  apply (smt Suc_leI append_butlast_last_id append_eq_append_conv append_take_drop_id diff_diff_cancel length_Cons length_drop length_greater_0_conv list.size(3))
  by (metis Suc_leI length_greater_0_conv ordered_cancel_comm_monoid_diff_class.le_add_diff semiring_normalization_rules(24))

lemma drop_concat_aux2 :
  "a # b # rest = pieces lst \<Longrightarrow>
   call_e lst (last lst) \<Longrightarrow>
   last b # concat rest @ [last lst] = drop (length a + length b - 1) lst"
apply (rule drop_concat_aux)
  apply (metis list.set_intros(1) list.set_intros(2) no_empty_pieces)
using call_e_from_pieces [of lst "last lst"]
  by (metis (no_types, lifting) Nil_is_append_conv append_butlast_last_id butlast_conv_take concat.simps(2) list.set_intros(1) no_empty_pieces take_eq_Nil)

lemma first_return_drop :
  "first_return (length lst - 1) lst \<Longrightarrow>
   length lst > 0 \<Longrightarrow>
   length (drop x lst) > 0 \<Longrightarrow>
   hd lst = hd (drop x lst) \<Longrightarrow>
   first_return (length (drop x lst) - 1) (drop x lst)"
by (simp add:first_return_def first_def)

(* take away a piece, have new call_e *)
lemma take_piece :
  "call_e lst (last lst) \<Longrightarrow>
   a # b # rest = pieces lst \<Longrightarrow>
   call_e ([last b]@concat rest@[last lst]) (last lst)"
apply (auto simp add: call_e_def)
using piece_last [of lst b]
  apply (metis One_nat_def Suc_lessD call_e_def hd_conv_nth length_greater_0_conv list.set_intros(1) list.set_intros(2))
apply (subgoal_tac
   "last b # concat rest @ [last lst] = drop (length a + length b - 1) lst")
apply (simp add:push_popL_def pathR_drop)
using drop_concat_aux2 [of a b rest lst]
  apply (simp add: call_e_def)

apply (subgoal_tac
   "last b # concat rest @ [last lst] = drop (length a + length b - 1) lst")
using first_return_drop [of lst "length a + length b - 1"]
apply simp
apply (subgoal_tac "lst \<noteq> []")
apply (subgoal_tac "length a + length b - 1 < length lst")
apply (subgoal_tac "hd (drop (length a + length b - Suc 0)
          lst) = last b")
apply (subgoal_tac "Suc (length (concat rest)) = length lst -
       Suc (length a + length b - Suc 0)")
apply simp
apply (subgoal_tac "call_e lst (last lst)")
using piece_last [of lst b]
  apply (metis hd_conv_nth list.set_intros(1) list.set_intros(2))
  apply (simp add: call_e_def)
  apply (metis One_nat_def Suc_diff_Suc length_Cons length_append_singleton length_drop nat.inject)
  apply (metis list.sel(1))
  apply (metis One_nat_def length_drop length_greater_0_conv list.distinct(1) zero_less_diff)
  apply (metis One_nat_def less_numeral_extra(2) list.size(3))
using drop_concat_aux2 [of a b rest lst]
  apply (simp add: call_e_def)
done

lemma combine_call_pieces :
   "concat (call_pieces lst) = clip (length lst-2) 1 lst"
apply (simp add:call_pieces_def)
  by (simp add: split_and_combine2)

lemma tlr_anti : "(a,b) \<in> tlR \<Longrightarrow> (b,a) \<in> tlR \<Longrightarrow> False"
unfolding tlR_def by auto

lemma tlr_anti_ref : "(a,a) \<in> tlR \<Longrightarrow> False"
unfolding tlR_def by auto

lemma first_call_piece :
  "call lst \<Longrightarrow>
   x \<in> set (call_pieces lst) \<Longrightarrow>
   call_e x (lst!1) \<Longrightarrow>
   x = take i (drop j lst) \<Longrightarrow>
   j > 1"
apply (subgoal_tac "length x > 0")
apply (subgoal_tac "i \<ge> length x")
apply (subgoal_tac "(x!0, lst!1) \<in> tlR")
using combine_call_pieces [of lst]
apply (simp add:clip_def)
apply (cases "j = 0")
apply (subgoal_tac "x!0 = lst!0")
apply (clarsimp simp:call_def)
using tlr_anti apply fastforce
  apply simp
apply (cases "j = 1")
apply (subgoal_tac "x!0 = lst!1")
apply (clarsimp simp:call_def)
using tlr_anti_ref apply fastforce
  apply simp
  apply linarith
apply (clarsimp simp:call_e_def)
  apply (metis append_take_drop_id gr_implies_not0 hd_append2 hd_drop_conv_nth take_eq_Nil)
  apply (simp )
apply (clarsimp simp:call_e_def)
  by linarith

lemma call_e_call :
   "call_e (tl lst) (last lst) \<Longrightarrow>
    hd lst = last lst \<Longrightarrow> call lst"
apply (auto simp add:call_e_def call_def)
  apply (metis One_nat_def Suc_lessD hd_conv_nth length_greater_0_conv length_tl nth_tl zero_less_diff)
apply (simp add:push_popL_def)
apply (case_tac lst)
  apply simp
apply simp
apply (case_tac list)
apply simp
apply simp
  apply (simp add: pathR.simps(1) push_pop_def)
  by (simp add: numeral_2_eq_2)

lemma take_tl :
"j > 0 \<Longrightarrow>
 take i (drop j lst) = tl (take (i+1) (drop (j-1) lst))"
by (metis One_nat_def Suc_pred diff_add_inverse2 drop_Suc tl_drop tl_take)

lemma hd_drop :
"length (drop (j-1) lst) > 0 \<Longrightarrow>
 j > 0 \<Longrightarrow>
 hd (drop (j-1) lst) = lst ! (j-1)"
  by (simp add: hd_drop_conv_nth)

fun concat_index :: "'a list list \<Rightarrow> nat \<Rightarrow> nat" where
  "concat_index [] x = 1"
| "concat_index (a#rest) x =
    (if x < length a then 0
     else 1 + concat_index rest (x-length a))"

lemma concat_index_good :
   "x < length (concat lst) \<Longrightarrow>
    concat_index lst x < length lst"
by (induction lst x rule:concat_index.induct; auto)

lemma find_piece1 :
   "x < length (concat ps) \<Longrightarrow>
    length (concat (take (concat_index ps x) ps)) \<le> x"
apply (induction ps x rule:concat_index.induct; auto)
  by linarith

lemma find_piece2 :
   "x < length (concat ps) \<Longrightarrow>
    length (concat (take (concat_index ps x + 1) ps)) > x"
apply (induction ps x rule:concat_index.induct; auto)
  by linarith

(*
lemma piece_from_set :
   "take i (drop j (concat ps)) \<in> set ps \<Longrightarrow>
    length (take i (drop j (concat ps))) > 0 \<Longrightarrow>
    ps ! concat_index ps j = (take i (drop j (concat ps)))"
*)

fun is_piece_at :: "'a list \<Rightarrow> 'a list list \<Rightarrow> nat \<Rightarrow> bool" where
  "is_piece_at x [] idx = False"
| "is_piece_at x (a#rest) idx =
    ((idx = 0 \<and> x = a) \<or>
     (is_piece_at x rest (idx-length a)) \<and> length a \<le> idx)"

(*
fun is_piece_at :: "'a list \<Rightarrow> 'a list list \<Rightarrow> nat \<Rightarrow> bool" where
  "is_piece_at x [] idx = False"
| "is_piece_at x (a#rest) idx =
    ((idx = 0 \<and> x = a) \<or>
     (is_piece_at x rest (idx-length a)) \<and> length a < idx)"
*)

lemma piece_first :
   "length x > 0 \<Longrightarrow>
    is_piece_at x ps j \<Longrightarrow>
    x!0 = concat ps ! j"
by (induction x ps j rule:is_piece_at.induct;
        auto simp add: nth_append)

lemma first_piece2 :
  "call lst \<Longrightarrow>
   is_piece_at x (call_pieces lst) j \<Longrightarrow>
   call_e x (lst!1) \<Longrightarrow>
   j > 0"
apply (subgoal_tac "length x > 0")
apply (subgoal_tac "(x!0, lst!1) \<in> tlR")
using combine_call_pieces [of lst]
apply (simp add:clip_def)
apply (cases "j = 0")
apply (subgoal_tac "x!0 = lst!1")
apply (clarsimp simp:call_def)
using tlr_anti_ref apply fastforce
using piece_first [of x "call_pieces lst" j]
  apply (metis Nitpick.size_list_simp(2) One_nat_def Suc_leI add.right_neutral call_invariant_before_after drop_Nil length_drop list.size(3) nth_drop nth_take zero_less_Suc)
  apply blast
by (auto simp:call_e_def hd_conv_nth)

fun is_piece_last :: "'a list \<Rightarrow> 'a list list \<Rightarrow> nat \<Rightarrow> bool" where
  "is_piece_last x [] idx = False"
| "is_piece_last x (a#rest) idx =
    ((idx = length a - 1 \<and> x = a) \<or>
     (is_piece_last x rest (idx-length a)) \<and> length a < idx)"

fun is_piece_adj :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list list \<Rightarrow> nat \<Rightarrow> bool" where
  "is_piece_adj y x [] idx = False"
| "is_piece_adj y x [a] idx = False"
| "is_piece_adj y x (a#b#rest) idx =
    ((Suc idx = length a \<and> y = a \<and> x = b \<and>
      length b > 0) \<or>
     (is_piece_adj y x rest (idx-length a)) \<and> length a < idx)"

lemma piece_at_concat_index :
   "length x > 0 \<Longrightarrow>
    is_piece_at x lst i \<Longrightarrow>
    x = lst ! concat_index lst i"
by (induction x lst i rule:is_piece_at.induct; auto)

lemma piece_last_concat_index :
   "length x > 0 \<Longrightarrow>
    is_piece_last x lst i \<Longrightarrow>
    x = lst ! concat_index lst i"
by (induction lst i arbitrary:x rule:concat_index.induct; auto)

lemma piece_at_concat_index_smaller :
   "length x > 0 \<Longrightarrow>
    i > 0 \<Longrightarrow>
    is_piece_at x lst i \<Longrightarrow>
    concat_index lst (i-1) < concat_index lst i"
by (induction x lst i rule:is_piece_at.induct; auto)

lemma piece_at_concat_index_gt0 :
   "length x > 0 \<Longrightarrow>
    i > 0 \<Longrightarrow>
    is_piece_at x lst i \<Longrightarrow>
    0 < concat_index lst i"
by (induction x lst i rule:is_piece_at.induct; auto)

lemma exists_piece_at :
   "x \<in> set lst \<Longrightarrow>
    length x > 0 \<Longrightarrow>
    \<exists>j. is_piece_at x lst j"
apply (induction lst ; auto)
apply (case_tac "x = a")
  apply auto
subgoal for a lst xa
apply (rule exI[where x = "xa + length a"])
apply simp
done
done

lemma piece_at_concat_length :
   "length x > 0 \<Longrightarrow>
    i > 0 \<Longrightarrow>
    is_piece_at x lst i \<Longrightarrow>
    length (concat (take (concat_index lst i) lst)) = i"
apply (induction lst arbitrary:i; auto)
apply (case_tac "length a = i"; auto)
  using find_piece1 in_set_takeD by force


lemma concat_find_last :
  "length (concat lst) > 0 \<Longrightarrow>
   \<exists>l \<in> set lst - {[]}. last l = last (concat lst)"
apply (induction lst; auto)
  using Nil_eq_concat_conv apply fastforce
  by (metis (no_types, lifting) DiffD1 DiffD2 DiffI Nil_eq_concat_conv insert_iff last_appendR)

lemma call_piece_last :
  "call lst \<Longrightarrow>
   l \<in> set (call_pieces lst) \<Longrightarrow>
   l \<noteq> [] \<Longrightarrow>
   last l = lst!1"
using decompose_call_pieces [of lst l]
apply simp
apply (cases "call_e l (lst ! Suc 0)")
apply auto
  apply (simp add: call_e_final)
apply (simp add:const_seq_def)
  using last_in_set by blast

lemma take_aux :
"length lst > 2 \<Longrightarrow>
 j > 0 \<Longrightarrow>
 j < length lst - 1 \<Longrightarrow>
 lst ! j =
 take (Suc (length lst - 3)) (drop (Suc 0) lst) !
    (j - Suc 0)"
  by (smt One_nat_def Suc_1 Suc_diff_1 Suc_diff_Suc Suc_lessD Suc_less_eq drop_0 drop_Suc length_tl nth_take nth_tl numeral_3_eq_3)

(*
  by (metis (no_types, lifting) Suc_diff_Suc Suc_leI Suc_lessD Suc_pred le_add_diff_inverse less_SucI nth_drop nth_take numeral_2_eq_2 numeral_3_eq_3)
*)

lemma concat_helper :
"j < length (concat (take n lst)) \<Longrightarrow> 
 concat (take n lst) ! j =  concat lst ! j"
apply (induction lst arbitrary:j n; auto)
apply (case_tac n; auto)
apply (case_tac "j < length a")
  apply (simp add: nth_append)
  apply (simp add: nth_append)
done

lemma length_concat_take :
  "length (concat (take n lst)) \<le> length (concat lst)"
apply (induction lst arbitrary:n; auto)
by (case_tac n; auto)

lemma extend_call_pieces :
  "call lst \<Longrightarrow>
   is_piece_at x (call_pieces lst) j \<Longrightarrow>
   call_e x (lst!1) \<Longrightarrow>
   call (lst!j # x)"
apply (subgoal_tac "j > 0")
defer
using first_piece2 apply fastforce
apply (rule call_e_call)
apply (cases "x = []")
apply (simp add:call_e_def)
apply clarsimp
  apply (simp add: call_e_final)
apply clarsimp
using piece_at_concat_length [of x j "call_pieces lst"]
apply simp
apply (subgoal_tac
  "lst!j = concat
       (take (concat_index (call_pieces lst) j)
         (call_pieces lst)) ! (j-1)")
apply (subgoal_tac "last x = lst!1")
apply simp
using concat_find_last
 [of "(take (concat_index (call_pieces lst) j)
         (call_pieces lst))"]
apply clarsimp
apply (subgoal_tac "l \<in> set (call_pieces lst)")
subgoal for l
using call_piece_last [of l lst]
  by (metis One_nat_def call_piece_last last_index)
  apply (meson in_set_takeD)
  apply (simp add: call_e_final)
apply (subgoal_tac "concat
     (take (concat_index (call_pieces lst) j)
       (call_pieces lst)) !
    (j - 1) = concat (call_pieces lst) ! (j-1)")
apply simp
using combine_call_pieces [of lst]
apply (simp add:clip_def)
apply (rule take_aux)
apply (simp add:call_def)
apply simp
defer
apply (rule concat_helper)
apply simp
apply (subgoal_tac "length
     (concat
       (take (concat_index (call_pieces lst) j)
         (call_pieces lst))) < length lst - 1")
apply simp
apply (subgoal_tac "length
     (concat (call_pieces lst)) < length lst - 1")
using length_concat_take [of
   "(concat_index (call_pieces lst) j)"
   "(call_pieces lst)"]
  apply linarith
apply (clarsimp simp add:call_def)
  by linarith


(*
definition call_inv2 :: "('a * 'a list \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) list \<Rightarrow> bool" where
"call_inv2 iv l =
   (call_e (map snd l) (snd (last l)) \<longrightarrow> iv (hd l) \<longrightarrow> iv (last l))"

definition call_inv :: "('a * 'a list \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) list \<Rightarrow> bool" where
"call_inv iv l = (call (map snd l) \<longrightarrow> iv (hd l) \<longrightarrow> iv (last l))"

definition stay_rel :: "('a * 'a list \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) rel" where
"stay_rel iv =
  {(a,b) | a b. length (snd a) = length (snd b) \<and> (iv a \<longrightarrow> iv b) }
\<union> {(a,b) | a b. length (snd a) \<noteq> length (snd b)}"
*)

definition iv_cond :: "('a * 'a list \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> ('a * 'a list) rel" where
"iv_cond iv level =
  {(a,b) | a b. length (snd a) = level \<and> length (snd b) = level \<and> (iv a \<longrightarrow> iv b) }
\<union> {(a,b) | a b. length (snd a) = level \<and> length (snd b) + 1 = level \<and> (iv a \<longrightarrow> iv b) }
\<union> {(a,b) | a b. length (snd a) + 1 = level \<and> length (snd b) = level \<and> (iv a \<longrightarrow> iv b) }
\<union> {(a,b) | a b. length (snd a) \<noteq> level \<and> length (snd b) \<noteq> level \<or>
                length (snd a) \<noteq> level \<and> length (snd b) \<noteq> level + 1 \<or>
                length (snd a) \<noteq> level + 1 \<and> length (snd b) \<noteq> level}"

(*
definition pcs :: "'a list list \<Rightarrow> 'a list list list" where
"pcs lst = filter (%x. x \<noteq> []) (call_pieces lst)"
*)

definition pcs :: "('a * 'a list) list \<Rightarrow> ('a * 'a list) list list" where
"pcs lst = filter (%x. x \<noteq> [])
   (let ilst = findIndices
       (clip (length lst-2) 1 (map (length \<circ> snd) lst))
       (length (snd (lst!1))) in
   indexSplit ilst (clip (length lst-2) 1 lst))"

lemma pcs_call_pieces :
   "a \<in> set (pcs lst) \<Longrightarrow>
    length lst > 1 \<Longrightarrow>
    map snd a \<in> set (call_pieces (map snd lst))"
by (simp add:pcs_def call_pieces_def clip_def
    drop_map index_split_map take_map)

(* perhaps there could be some kind of driver
   that generates a good induction principle
   *)

lemma get_last_gen :
"j < length ps \<Longrightarrow>
 [] \<notin> set ps \<Longrightarrow>
 concat ps ! (length (concat (take (Suc j) ps)) - 1) =
 last (ps ! j)"
apply (induction ps arbitrary:j; auto)
apply (case_tac j; auto)
  apply (simp add: last_conv_nth nth_append)
apply (case_tac ps; auto)
  by (metis Nat.add_diff_assoc Suc_leI add_gr_0 length_greater_0_conv nth_append_length_plus)

lemma pcs_not_empty :
"[] \<notin> set (pcs lst)"
by (auto simp add:pcs_def)

lemma combine_pcs :
   "concat (pcs lst) = clip (length lst-2) 1 lst"
by (simp add: pcs_def concat_filter split_and_combine2)

lemma clip_nth :
"length lst > 2 \<Longrightarrow>
 j > 0 \<Longrightarrow>
 j < length lst-1 \<Longrightarrow>
 clip (length lst - 2) 1 lst ! (j-1) = lst ! j"
by (simp add:clip_def)

lemma has_pieces :
"length lst > 2 \<Longrightarrow>
 length (pcs lst) > 0"
apply (case_tac lst)
apply (auto simp: pcs_def call_pieces_def clip_def)
apply (case_tac list)
apply (auto simp: pcs_def call_pieces_def clip_def)
apply (case_tac lista)
apply (auto simp: pcs_def call_pieces_def clip_def)
done

lemma has_piece :
"length lst > 2 \<Longrightarrow>
 \<exists>xs\<in>set (take (Suc j) (pcs lst)). xs \<noteq> []"
apply (cases "pcs lst")
using has_pieces apply force
  by (metis list.set_intros(1) pcs_not_empty take_Suc_Cons)

lemma concat_pcs_length :
  "length lst > 2 \<Longrightarrow>
   length (concat (pcs lst)) < length lst - 1"
by (simp add:combine_pcs clip_def)

lemma get_last :
"length lst > 2 \<Longrightarrow>
 j < length (pcs lst) \<Longrightarrow>
 lst ! length (concat (take (Suc j) (pcs lst))) = last (pcs lst ! j)"
using get_last_gen [of j "pcs lst"]
apply (simp add:pcs_not_empty combine_pcs)
using clip_nth [of lst "length (concat (take (Suc j) (pcs lst)))"]
apply (simp add:has_piece)
using concat_pcs_length [of lst]
  by (metis (no_types, lifting) One_nat_def le_trans length_concat_take not_le)

lemma get_first_gen :
"j < length ps \<Longrightarrow>
 concat ps ! length (concat (take j ps)) = hd (ps ! j)"
oops


lemma get_first :
"lst ! (length (concat (take j (pcs lst))) + 1) = hd (pcs lst ! j)"
oops

lemma call_invariant_aux :
 "\<forall>m<length lst.
       \<forall>x. m = length x \<longrightarrow>
           call (map snd x) \<longrightarrow>
           pathR (iv_cond iv (length (snd (x ! 1)))) x \<longrightarrow>
           iv (x ! 1) \<longrightarrow> iv (last x) \<Longrightarrow>
    call (map snd lst) \<Longrightarrow>
    pathR (iv_cond iv (length (snd (lst ! 1)))) lst \<Longrightarrow>
    j < length (pcs lst) \<Longrightarrow>
    iv (lst!1) \<Longrightarrow>
    iv (lst ! length (concat (take (Suc j) (pcs lst))))"
apply (induction j)
apply auto
apply (cases "pcs lst")
apply simp
apply (subst get_last)
apply simp

lemma call_invariant :
  "call (map snd lst) \<Longrightarrow>
   pathR (iv_cond iv (length (snd (lst!1)))) lst \<Longrightarrow>
   iv (lst!1) \<Longrightarrow>
   iv (last lst)"
apply (induction "length lst" arbitrary:lst rule:nat_less_induct)

subgoal for lst

apply (induction "call_pieces (map snd lst)" arbitrary:lst)



lemma call_invariant :
  "\<forall>l \<in> psublists lst. call_inv2 iv l \<Longrightarrow> 
   pathR (stay_rel iv) lst \<Longrightarrow>
   (* exit must be good *)
   (iv (lst!(length lst-2)) \<Longrightarrow> iv (last lst)) \<Longrightarrow>
   (* call outs should be good *)
   pathR (callout_rel iv (length (snd (hd lst)))) lst \<Longrightarrow>
   call_inv2 iv lst"

(* can be solved using a case analysis using call pieces *)

apply (induction "length (pieces (map snd lst))")
apply (auto simp:call_inv2_def)
using call_e_has_pieces apply force

oops

end
