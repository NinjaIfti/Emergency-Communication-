# 🔧 CMake Selection Guide

## 📱 If You See a CMake List Prompt:

### **What to Select:**
1. **Default/Recommended** - Usually the highest version (e.g., "cmake 3.22.1" or "cmake 3.24.x")
2. **Or press Enter** - Uses the default selection
3. **Latest version available** - If multiple options show

### **Example Prompt:**
```
Select CMake to use:
  1) cmake 3.22.1
  2) cmake 3.24.1
  3) cmake 3.26.0 (recommended)

Enter selection [default is 3.26.0]:
```

**Answer:** Just press **Enter** or type **3** (for the recommended one)

---

## ✅ Quick Solution:

**For most Flutter apps, you don't need to worry about CMake - it auto-detects!**

If you're stuck on the prompt:
- Press **Enter** (uses default)
- Or select the **highest/recommended version**

---

## 🚀 After Selection:

The build will continue automatically. CMake is only used if you have:
- Native C/C++ code
- Plugins with native code
- NDK requirements

**Your Flutter app uses it automatically, so just accept the default!**


