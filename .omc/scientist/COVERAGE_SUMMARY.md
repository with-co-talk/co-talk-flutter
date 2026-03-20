# Co-Talk Flutter Test Coverage Analysis
**Date**: 2026-02-17  
**Overall Coverage**: 42.30% (5,699/13,472 lines)

---

## 📊 Executive Dashboard

| Metric | Value |
|--------|-------|
| Total Files | 198 |
| Total Lines | 13,472 |
| Covered Lines | 5,699 |
| **Uncovered Lines** | **7,773** |
| Overall Coverage | **42.30%** |
| Files Without Tests | 196/198 (99%) |

---

## 🎯 Top 10 Priority Test Targets (Excluding Generated Files)

| # | File | Uncovered Lines | Current Coverage | Layer |
|---|------|-----------------|------------------|-------|
| 1 | `presentation/pages/chat/widgets/message_bubble.dart` | 470 | 27.1% | UI Component |
| 2 | `presentation/pages/profile/profile_view_page.dart` | 398 | 0.0% | Page |
| 3 | `presentation/pages/profile/edit_profile_page.dart` | 268 | 0.4% | Page |
| 4 | `presentation/pages/chat/widgets/message_input.dart` | 230 | 31.1% | UI Component |
| 5 | `presentation/pages/profile/profile_history_page.dart` | 230 | 0.0% | Page |
| 6 | `data/datasources/remote/chat_remote_datasource.dart` | 199 | 34.1% | Data Layer |
| 7 | `presentation/pages/settings/chat_settings_page.dart` | 162 | 0.6% | Page |
| 8 | `presentation/pages/chat/media_gallery_page.dart` | 159 | 0.0% | Page |
| 9 | `core/network/websocket_service.dart` | 149 | 31.3% | Network |
| 10 | `presentation/pages/settings/account_deletion_page.dart` | 142 | 0.7% | Page |

**Impact**: These 10 files contain **2,407 uncovered lines** (31% of total uncovered code).

---

## 🏗️ Architecture Layer Breakdown

### Presentation Layer (47.9% of uncovered lines)
| Sub-Layer | Files | Lines | Coverage | Uncovered | Priority |
|-----------|-------|-------|----------|-----------|----------|
| **presentation/pages** | 47 | 5,342 | **30.3%** | **3,723** | 🔴 CRITICAL |
| presentation/blocs | 45 | 2,370 | 69.6% | 720 | 🟡 MEDIUM |
| presentation/widgets | 5 | 273 | 40.7% | 162 | 🟠 HIGH |

### Data Layer (26.2% of uncovered lines)
| Sub-Layer | Files | Lines | Coverage | Uncovered | Priority |
|-----------|-------|-------|----------|-----------|----------|
| **data/datasources/local** | 14 | 2,038 | **20.9%** | **1,613** | 🔴 CRITICAL |
| data/datasources/remote | 8 | 681 | 37.9% | 423 | 🟠 HIGH |
| data/repositories | 8 | 277 | 50.2% | 138 | 🟡 MEDIUM |
| data/models | 20 | 690 | 64.2% | 247 | 🟢 LOW |

### Core Layer (8.9% of uncovered lines)
| Sub-Layer | Files | Lines | Coverage | Uncovered | Priority |
|-----------|-------|-------|----------|-----------|----------|
| core/network | 11 | 807 | 45.4% | 441 | 🟠 HIGH |
| core/services | 7 | 258 | 61.2% | 100 | 🟡 MEDIUM |
| core/utils | 10 | 211 | 68.7% | 66 | 🟢 LOW |
| core/other | 10 | 192 | 67.2% | 63 | 🟢 LOW |

### Domain Layer (0.7% of uncovered lines)
| Sub-Layer | Files | Lines | Coverage | Uncovered | Priority |
|-----------|-------|-------|----------|-----------|----------|
| domain | 11 | 259 | **78.8%** | 55 | ✅ GOOD |

---

## 💡 Strategic Recommendations

### Phase 1: Quick Wins (1-2 weeks)
**Target**: Increase coverage to 55%+

1. **Add widget tests for top 5 pages** (1,528 uncovered lines)
   - `profile_view_page.dart` - Profile display logic
   - `edit_profile_page.dart` - Form validation, image upload
   - `profile_history_page.dart` - History list rendering
   - `chat_settings_page.dart` - Settings toggles
   - `media_gallery_page.dart` - Media grid display

2. **Test critical UI components** (700 uncovered lines)
   - `message_bubble.dart` - Message display variants (text, image, video, deleted)
   - `message_input.dart` - Input field, image picker, emoji

3. **Mock-based remote datasource tests** (199 uncovered lines)
   - `chat_remote_datasource.dart` - HTTP request/response mocking

### Phase 2: Core Infrastructure (2-3 weeks)
**Target**: Increase coverage to 70%+

4. **WebSocket testing** (149 uncovered lines)
   - `websocket_service.dart` - Connection lifecycle, reconnection logic

5. **Data layer completion** (1,613 uncovered lines)
   - Skip `app_database.g.dart` (generated - 1,244 lines)
   - Test `entity_converters.dart` - DB entity conversions (108 lines)
   - Test local datasources with in-memory database

6. **Network layer** (441 uncovered lines)
   - Certificate pinning, auth interceptors, retry logic

### Phase 3: Comprehensive Coverage (ongoing)
**Target**: Maintain 80%+ coverage

7. **BLoC layer refinement** (720 uncovered lines)
   - Already at 69.6% - focus on edge cases and error states
   
8. **Integration tests**
   - End-to-end user flows (login → chat → send message)

---

## ⚠️ Known Limitations

1. **Generated files skew metrics**: `app_database.g.dart` (1,244 lines) is auto-generated and cannot be manually tested. Actual coverage without generated code: **47.3%**

2. **Widget tests require extensive mocking**: Presentation layer pages depend on BLoCs, repositories, and navigation - setup overhead is significant.

3. **WebSocket testing complexity**: Real-time messaging requires mock server or test harness.

---

## 📈 Coverage Goals

| Milestone | Target Coverage | Key Deliverables |
|-----------|----------------|------------------|
| **Current** | 42.3% | Baseline established |
| **Phase 1** | 55% | Top 10 files tested |
| **Phase 2** | 70% | Core infra tested |
| **Phase 3** | 80% | Production-ready |

---

## 🔗 References

- Full analysis: `.omc/scientist/reports/20260217_121428_coverage_report.md`
- LCOV data: `coverage/lcov.info`
- Test directory: `test/`

