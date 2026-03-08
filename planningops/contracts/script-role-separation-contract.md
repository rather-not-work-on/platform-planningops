# Script Role Separation Contract

## Purpose
Prevent uncontrolled script sprawl by separating recurring core scripts from one-off bootstrap/migration scripts.

## Rules
1. Recurring runtime/CI entrypoints live in:
   - `planningops/scripts/`
   - `planningops/scripts/core/`
   - `planningops/scripts/federation/`
2. Non-recurring scripts live in:
   - `planningops/scripts/oneoff/`
3. If backward compatibility is required, keep a thin wrapper at root path and register it in the compatibility wrapper map.
4. Any role-map change must update:
   - `planningops/config/script-role-map.json`
   - `planningops/scripts/validate_script_roles.py`
   - `planningops/scripts/test_validate_script_roles_contract.sh`
5. Wrapper lifecycle changes must update `planningops/config/wrapper-deprecation-map.json`.
6. Validation must ignore filesystem metadata files (for example `._*`, `.DS_Store`) so external-drive artifacts do not create false failures.

## Verification
- `bash planningops/scripts/test_validate_script_roles_contract.sh`
- `bash planningops/scripts/test_validate_wrapper_deprecation_contract.sh`
