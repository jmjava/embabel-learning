# 🚀 PR Review Quick Start

**Problem:** IDE always seems out of sync when reviewing PRs

**Solution:** Use these commands before reviewing any PR

## ⚡ Quick Fix (30 seconds)

```bash
# 1. Check sync status
esyncstatus all

# 2. If behind, sync
esync

# 3. Review PR (this handles sync automatically)
ereview agent 1223
```

## 📖 Full Guide

See **[docs/PR-REVIEW-GUIDE.md](docs/PR-REVIEW-GUIDE.md)** for:
- Complete step-by-step workflow
- Common issues and fixes
- How to keep IDE in sync
- Pro tips

## 🎯 Key Commands

| What You Want | Command |
|---------------|---------|
| Check if in sync | `esyncstatus all` |
| Sync repositories | `esync` |
| Review PR (auto-sync) | `ereview agent 123` |
| Refresh IDE | `Cmd/Ctrl+Shift+P` → "Developer: Reload Window" |

---

**That's it!** The `ereview` command handles everything automatically.
