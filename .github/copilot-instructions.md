# BCOE&M 2.8 - AI Coding Agent Instructions

## Project Overview
**Brew Competition Online Entry & Management (BCOE&M)** is a legacy PHP 7.3 application for managing homebrewing competitions. This is v2.8, a maintenance-only branch updating style references to BJCP/AABC 2025 Cider standards. The production version (3.0.0) is maintained in a separate repository.

## Architecture

### Core Request Flow
1. **Entry Point**: `index.php` is the single delivery vehicle for all modules
2. **Bootstrap Sequence**:
   - `paths.php` → defines all directory constants (ROOT, ADMIN, INCLUDES, etc.)
   - `site/bootstrap.php` → preflight checks, session management, URL variable parsing
   - Section-based routing via `$section` URL parameter
3. **Section Resolution**: Valid sections defined in `bootstrap.php` (line 31) route to files in `/sections/*.sec.php`
4. **Admin Gating**: Admin sections check `$_SESSION['userLevel']` ≤ 1 and require `lib/admin.lib.php`

### Database Architecture
- **Raw mysqli**: No ORM. Direct `mysqli_query()` calls throughout
- **Table Prefix**: All tables use `$prefix` variable (defined in `site/config.php`)
- **Query Location**: Queries live in `/includes/db/*.db.php` files, not inline
- **Pattern**: Each page loads specific `.db.php` files containing prepared queries

Example from [includes/db/dropoff.db.php](includes/db/dropoff.db.php):
```php
$query_dropoff = sprintf("SELECT * FROM %s", $drop_off_db_table);
$dropoff = mysqli_query($connection,$query_dropoff) or die (mysqli_error($connection));
```

### Key Architectural Components
- **Templating**: TinyButStrong (TBS) template engine in `classes/tiny_but_strong/`. Used via `clsTinyButStrong` class in output generation
- **Form Processing**: `includes/process.inc.php` handles all DB write operations (inserts/updates/deletes)
- **Utility Libraries**: `lib/*.lib.php` contains reusable functions (common, output, admin, email, etc.)
- **Evaluation Module**: `eval/*.eval.php` for electronic scoresheets with descriptor arrays (beer/cider/mead specific)

### Directory Structure Patterns
```
/includes/db/        → Database query files
/lib/                → Shared function libraries  
/sections/           → Page section templates
/admin/              → Admin-only functionality (*.admin.php)
/eval/               → Electronic evaluation/scoresheet system
/output/             → Report/label generation
/classes/            → Third-party libraries (PHPMailer, FPDF, HTMLPurifier, etc.)
/templates/          → TBS HTML templates for labels/scoresheets
/mods/               → Extension/plugin system (actively used)
/ajax/               → AJAX endpoint handlers (*.ajax.php)
```

## Critical Conventions

### File Naming
- **Admin pages**: `{feature}.admin.php` in `/admin/`
- **Database queries**: `{feature}.db.php` in `/includes/db/`
- **Page sections**: `{feature}.sec.php` in `/sections/`
- **Libraries**: `{category}.lib.php` in `/lib/`

### Constants & Globals
- **Paths**: Always use directory constants (ROOT, ADMIN, INCLUDES, etc.) never relative paths
- **Database**: `$prefix` (configurable in `site/config.php`), `$database`, `$connection` are global
- **URLs**: `$base_url` for all internal links
- **Session Variables**: Prefixed with feature name (e.g., `$_SESSION['contestName']`, `$_SESSION['userLevel']`)

### Security Patterns
- **Sanitization**: `sterilize()` function in `includes/scrubber.inc.php` for all inputs
- **Password Hashing**: phpass library (`PasswordHash` class) with 8 rounds
- **SQL Escaping**: `mysqli_real_escape_string()` before queries (though sprintf pattern prevalent)
- **Admin Checks**: Must verify `$_SESSION['userLevel'] <= 1` for privileged operations

### Common Functions (lib/common.lib.php)
- `check_setup($table, $database)` → Verify table exists before queries
- `build_action_link()` → Generate admin action links with icons
- `sterilize()` → Input sanitization
- `version_check()` → Update system table with current version

## Development Workflows

### Local Development with Docker
```bash
# Start environment (requires SSL certs: server.crt, server.key)
docker-compose up -d

# Access: https://localhost:8000 (HTTPS only)
# Database: MySQL 8.0 container (see docker-compose.yml)
```

**Note**: Dockerfile expects `server.crt` and `server.key` in project root for SSL configuration.

### Database Changes
1. Update/create query in appropriate `/includes/db/*.db.php` file
2. For writes, route through `includes/process.inc.php` with `$dbTable` and `$action` parameters
3. Never inline queries; maintain separation between logic and data access

### Adding Admin Features
1. Create `feature.admin.php` in `/admin/`
2. Add corresponding queries in `/includes/db/feature.db.php`
3. Update section array in `bootstrap.php` if new section needed
4. Always load `lib/admin.lib.php` for admin functions

### Template Output (Labels/Reports)
1. HTML templates in `/templates/` use TBS block syntax: `[block.fieldname]`
2. Load TBS: `$TBS = new clsTinyButStrong;`
3. Merge data: `$TBS->MergeBlock('blockname', 'array', $data_array);`
4. See [output/entry.output.php](output/entry.output.php) for reference implementation

## Common Pitfalls

### Session Management
- Sessions use `$prefix_session` suffix (defined in config)
- Check `$logged_in` boolean before displaying user-specific content
- Always verify `$_SESSION['userLevel']` for access control

### URL Construction
- Never hardcode URLs; use `$base_url` variable
- SEF (Search Engine Friendly) URLs toggled via `$_SESSION['prefsSEF']`
- Use `prep_redirect_link()` before header redirects

### Style/Category Data
- Style definitions in `includes/styles.inc.php` as PHP arrays (not DB)
- Supports BJCP beer styles + cider/mead categories
- Electronic scoresheets use descriptors from `eval/descriptors.eval.php`

### Authentication Flow
Login handled in `includes/logincheck.inc.php`:
1. Password hashed with `md5()` then validated via `PasswordHash->CheckPassword()`
2. Username normalized to lowercase
3. Session + cookie registration on success
4. Redirects: admins → `/admin`, users → `/list`

## Dependencies
Third-party libraries in `/classes/`:
- **PHPMailer**: Email sending
- **FPDF**: PDF generation
- **TinyButStrong**: Template engine
- **HTMLPurifier**: XSS prevention
- **phpass**: Password hashing
- **QR Code**: Entry check-in QR generation
- **Parsedown/Markdownify**: Markdown processing

## Testing Considerations
- No automated test suite or overarching testing strategy exists
- Manual testing against MySQL 5.7+/8.0 required
- Test all form submissions through `includes/process.inc.php`
- Verify admin gating with `userLevel > 1` test account
- Docker environment useful for isolated testing (MySQL 8.0)

## Key Files to Reference
- [index.php](index.php) - Main router
- [site/bootstrap.php](site/bootstrap.php) - Initialization and section routing
- [lib/common.lib.php](lib/common.lib.php) - Core utility functions
- [includes/process.inc.php](includes/process.inc.php) - Form processing hub
- [includes/db/common.db.php](includes/db/common.db.php) - Common queries
