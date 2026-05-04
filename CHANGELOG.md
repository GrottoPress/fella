# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-05-04

### Added
- Log HTTP Referer
- Log response body size
- Log request ID
- Add `.sensitive_params` setting

### Fixed
- Sanitize URL and user agent strings
- Limit length of URL and user agents to 512 characters

### Removed
- Remove `.skip_if` setting

## [0.1.1] - 2024-10-02

### Fixed
- Fix compile error calling `.compare_versions` with `Fella::VERSION`

## [0.1.0] - 2023-12-20

### Added
- Initial public release
