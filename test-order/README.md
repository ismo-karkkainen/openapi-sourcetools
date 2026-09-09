# Test Cases for openapi-order

This directory contains test document and order file pairs for testing the openapi-order program.

Tests listed here, and this file, were added by Claude Code.

## Test Files

Each test consists of two files:
- `<prefix>-doc.yaml` - The document to be ordered
- `<prefix>-order.yaml` - The order instructions

## Test Coverage

### 1. basic-hash
**Code paths:** Hash key ordering with exact matches
**Tests:** Basic top-level hash ordering following explicit key order

### 2. wildcard
**Code paths:** Wildcard (*) matching in order arrays, unmatched key handling
**Tests:** Keys explicitly listed come first, wildcard catches remaining keys, alphabetically sorted within wildcard group

### 3. regex
**Code paths:** Regex pattern matching (re: prefix), multiple pattern groups
**Tests:** Named keys, regex patterns (^x-), wildcard, and regex at end (example[s]?)

### 4. no-wildcard
**Code paths:** Order array without wildcard, implicit wildcard handling
**Tests:** Matched keys come first, unmatched keys placed last (auto-added nil)

### 5. priority
**Code paths:** Multiple regex patterns with priority resolution
**Tests:** Exact matches have highest priority, then regexes by position, wildcard last

### 6. array-sort
**Code paths:** Array sorting by object properties
**Tests:** Array of objects sorted by 'name' property value

### 7. array-multi-key
**Code paths:** Multi-key array sorting, comparison cascading
**Tests:** Sort by category, then priority, then name (multiple sort keys)

### 8. array-missing-keys
**Code paths:** Array sorting with missing keys in objects
**Tests:** Objects with missing sort keys placed after objects with the key

### 9. mixed-array
**Code paths:** Arrays with mixed content types (objects, scalars)
**Tests:** Objects sort by specified keys, scalars end up last

### 10. nested
**Code paths:** Nested structure ordering, recursive descent
**Tests:** Multi-level nesting with order specified at each level (info.contact, paths.*.get.responses)

### 11. deep-nesting
**Code paths:** Very deep nesting (4+ levels)
**Tests:** Order propagation through deeply nested structures

### 12. ref
**Code paths:** $ref special handling, reference ordering
**Tests:** $ref key comes first, then other keys in specified order

### 13. self-ref
**Code paths:** $self special key handling
**Tests:** $self placeholder in order for positioning relative to matched/unmatched keys

### 14. empty
**Code paths:** Empty hash and array handling
**Tests:** Empty structures preserved, no errors on empty collections

### 15. scalar-warning
**Code paths:** Scalar value where order expects object/array, warning generation
**Tests:** Generates warnings for mismatched types, continues processing

### 16. complex-openapi
**Code paths:** Comprehensive OpenAPI structure with multiple features
**Tests:** Real-world OpenAPI document with paths, components, schemas, parameters, nested operations

## Code Path Coverage

The tests cover:
- ✓ Hash key ordering (order_hash function)
- ✓ Array element sorting (order_array function)
- ✓ Exact string matching (converted to anchored regexes)
- ✓ Wildcard matching (*)
- ✓ Regex patterns (re: prefix)
- ✓ Priority resolution (exact > regex > wildcard)
- ✓ Nested structure traversal (recursive order_document calls)
- ✓ Multi-key comparison (array_item_compare)
- ✓ Missing key handling (in both hashes and arrays)
- ✓ Mixed content types
- ✓ Special keys ($ref, $self)
- ✓ Warning generation (scalar where order expects collection)
- ✓ Regex conversion (make_regexes function, both Array and Hash branches)
- ✓ Empty structure handling
