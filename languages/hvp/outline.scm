; Outline/symbols query for HVP (Hierarchical Verification Plan).
;
; Zed's outline convention: @item marks the node that becomes an outline
; entry, @context captures leading keyword text shown next to the name,
; @name captures the entry's display name. Nesting is inferred from tree
; containment (a metric_block inside a plan_block nests under it), so no
; explicit parent/child wiring is needed here.

(plan_block
  "plan" @context
  name: (identifier) @name) @item

(feature_block
  "feature" @context
  name: (identifier) @name) @item

(metric_block
  "metric" @context
  name: (identifier) @name) @item

(measure_block
  "measure" @context
  name: (identifier) @name) @item

(override_block
  "override" @context
  name: (identifier) @name) @item

(filter_block
  "filter" @context
  name: (identifier) @name) @item

(subplan_statement
  "subplan" @context
  name: (identifier) @name) @item
