# 📖 Fundamentals – SAP & ABAP

## What is SAP and ABAP
- **SAP**: ERP system that manages sales, purchasing, logistics, production, accounting.  
- **ABAP**: programming language used to read/write data in SAP tables and create business logic (reports, interfaces, printouts).

---

## Standard vs Custom
- **Standard** = provided by SAP (transactions/reports “out of the box”).  
- **Custom** = our own developments (prefix **Z** or **Y**).  
  - Example: `Z_FM_REPORTORDER4`, `YCS_TESTPP`.

---

## Basic Tools
- **SE11** → Data Dictionary (tables, structures, domains).  
- **SE38** → Report programs.  
- **SE80** → Object Navigator (full development environment).  
- **SE93** → Transaction codes.  
- **Debugger** → to analyze program execution step by step.

---

## Typical Report Structure
```abap
REPORT z_demo.

INCLUDE z_demo_top.   " global types / variables
INCLUDE z_demo_sel.   " selection screen (parameters, select-options)
INCLUDE z_demo_form.  " logic (FORM routines)
WRITE & FORM Examples
Simple WRITE
REPORT z_demo_write.

WRITE 'Hello World'.
WRITE / sy-datum.   " print system date
FORM routine
FORM somma USING a b CHANGING res.
  res = a + b.
ENDFORM.
 
