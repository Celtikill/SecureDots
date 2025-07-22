# Diagram Accessibility Standards - Critical Memory Reference

## ⚠️ CRITICAL RULE: Mermaid Diagram Color Management

**The Fundamental Principle:**
NEVER override text color unless you are also overriding background color.

### The Correct Approach

**Mermaid Accessibility Comment Standard:**
```
%% ACCESSIBILITY RULE: Only specify color when changing fill
%% WHITE FILLS: fill:#ffffff,color:#000 (black text on white)  
%% DEFAULT FILLS: No color override (Mermaid handles contrast)
```

### Implementation Rules

1. **White Fill Elements**: `fill:#ffffff,color:#000`
   - Used when you want white background with guaranteed black text
   - Ensures 21:1 contrast ratio (perfect accessibility)

2. **Default Background Elements**: `stroke:#000,stroke-width:Xpx` 
   - NO fill override, NO color override
   - Let Mermaid handle text contrast automatically
   - Mermaid's defaults provide good contrast

3. **Pattern-Based Differentiation**: 
   - `stroke-dasharray` for visual patterns (dashed, dotted)
   - `stroke-width` for importance hierarchy
   - Border styling instead of color coding

### What NOT To Do

❌ **NEVER**: `color:#000` on elements without `fill:#ffffff`
❌ **NEVER**: Universal color application to all elements  
❌ **NEVER**: Assume all elements need explicit color specification

### Quality Assurance Checklist

For every diagram:
- [ ] Only elements with `fill:#ffffff` have `color:#000`
- [ ] Elements with default backgrounds have NO color override
- [ ] Visual differentiation uses borders, not color
- [ ] All diagrams have comprehensive text descriptions
- [ ] Accessibility rules documented in comments

## Historical Context

**Previous Error**: Applied `color:#000` universally to all elements, causing:
- Black text on dark default backgrounds = unreadable
- Violated fundamental accessibility principle
- Required systematic correction across all diagrams

**Lesson Learned**: Accessibility requires understanding the system defaults, not overriding everything.

## Documentation Location

Full accessibility standards documented in:
- `/home/user0/dotfiles/docs/ARCHITECTURE.md` - Complete standards section
- All Mermaid diagrams include accessibility comment blocks
- Each diagram has comprehensive text alternative descriptions

This file serves as a critical memory reference to prevent regression of accessibility improvements.