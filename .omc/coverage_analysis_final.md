# Final Coverage Analysis Report

**Generated:** 2026-02-25  
**Analysis File:** `coverage/lcov.info`

---

## Overall Coverage Summary

| Metric | Value |
|--------|-------|
| **Total Lines** | 13,574 |
| **Lines Tested** | 8,109 |
| **Coverage %** | **59.74%** |
| **Session Start** | 49.86% |
| **After Round 1** | 58.68% |
| **Total Session Gain** | +9.88% |
| **This Update** | +1.06% |

✅ **Steady progress** - Moving toward 60% threshold with consistent improvements across rounds.

---

## Coverage by Directory

| Directory | Files | Lines | Hit | Coverage | Status |
|-----------|-------|-------|-----|----------|--------|
| **lib/domain** | 11 | 270 | 240 | **88.89%** | 🟢 Excellent |
| **lib/presentation** | 100 | 8,112 | 5,062 | **62.40%** | 🟡 Good |
| **lib/core** | 37 | 1,462 | 850 | **58.14%** | 🟡 Fair |
| **lib/data** | 51 | 3,714 | 1,956 | **52.67%** | 🟡 Fair |
| **lib/di** | 1 | 16 | 1 | **6.25%** | 🔴 Critical |

### Analysis
- **Domain layer** is strongest (88.89%) - Entity and interface definitions well-covered
- **Presentation layer** needs work (62.40%) - 100 files, many UI pages untested
- **Data layer** (52.67%) - Repository implementations and datasources need tests
- **DI container** (6.25%) - Only 16 lines, injectable configuration

---

## Files Updated This Session

| File | Lines | Hit | Coverage | Status |
|------|-------|-----|----------|--------|
| `lib/presentation/pages/profile/profile_view_page.dart` | 398 | 126 | **31.66%** | 🔴 Needs tests |
| `lib/core/utils/save_image_to_gallery.dart` | 12 | 12 | **100.00%** | 🟢 Complete |
| `lib/core/constants/app_constants.dart` | 1 | 0 | **0.00%** | ⚠️ Uncovered |

### Notes
- ✅ `save_image_to_gallery.dart` is fully tested (100%)
- ⚠️ `app_constants.dart` - Single constant line, likely doesn't need testing
- 🔴 `profile_view_page.dart` - Only 31.66% coverage, needs additional test cases

---

## Critical Gaps - Zero Coverage

**Count:** 1 file

| File | Lines | Reason |
|------|-------|--------|
| `lib/core/constants/app_constants.dart` | 1 | Single constant declaration - coverage not required |

✅ Only 1 file with 0% coverage - excellent state for production code.

---

## Low Coverage Files Requiring Tests (< 50%, >20 lines)

| # | File | Lines | Coverage | Priority |
|---|------|-------|----------|----------|
| 1 | `presentation/pages/settings/notification_settings_page.dart` | 142 | 0.70% | 🔴 HIGH |
| 2 | `presentation/pages/auth/forgot_password_page.dart` | 128 | 0.78% | 🔴 HIGH |
| 3 | `presentation/pages/settings/change_password_page.dart` | 97 | 1.03% | 🔴 HIGH |
| 4 | `presentation/pages/auth/find_email_page.dart` | 56 | 1.79% | 🟠 MEDIUM |
| 5 | `presentation/pages/friends/received_requests_page.dart` | 91 | 2.20% | 🟠 MEDIUM |
| 6 | `presentation/pages/friends/sent_requests_page.dart` | 87 | 2.30% | 🟠 MEDIUM |
| 7 | `presentation/pages/settings/security_settings_page.dart` | 25 | 4.00% | 🟠 MEDIUM |
| 8 | `presentation/pages/image_editor/image_editor_page.dart` | 22 | 4.55% | 🟠 MEDIUM |
| 9 | `presentation/pages/profile/handlers/image_picker_handler.dart` | 42 | 4.76% | 🟠 MEDIUM |
| 10 | `core/network/certificate_pinning_interceptor.dart` | 36 | 5.56% | 🟠 MEDIUM |

### Observations
- **Settings & Auth Pages**: Settings, password change, forgot password pages need comprehensive widget tests
- **Image Handling**: Image editor and picker handler need more test coverage
- **Network**: Certificate pinning logic needs unit tests
- **Recommendation**: Target notification_settings_page.dart first (highest impact - 142 lines)

---

## Recommendations for Next Session

### Immediate Actions (60-70% coverage)
1. **Write widget tests for:** `notification_settings_page.dart`, `forgot_password_page.dart`
2. **Write unit tests for:** `certificate_pinning_interceptor.dart`, `websocket_subscription_manager.dart`
3. **Target 5-10 more high-impact files** in presentation layer

### Medium-term (70-80% coverage)
- Focus on data layer (currently 52.67%)
- Improve core network and utilities
- Complete remaining presentation pages

### Notes
- Domain layer is in excellent shape (88.89%) - maintain this
- Presentation layer has the most test opportunities (100 files, 62.40% coverage)
- Session progress has been steady: 49.86% → 58.68% → 59.74%

