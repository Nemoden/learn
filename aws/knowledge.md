  From aws-cli.txt:
  $ aws configure --profile userprod
  AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
  AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  Default region name [None]: us-west-2
  Default output format [None]: json

  So yes, aws configure --profile claude is the official AWS CLI method to add a named profile with static credentials.

  This will:
  1. Prompt for access key, secret key, region, output format
  2. Auto-create ~/.aws/credentials with [claude] section
  3. Auto-update ~/.aws/config with [profile claude] section

  Your [default] profile with login_session stays untouched.

  ★ Insight ─────────────────────────────────────
  • Always verify with official docs—good instinct! AWS CLI behavior can change between versions
  • aws configure handles edge cases—file permissions (600), concurrent writes, proper ini formatting
  ─────────────────────────────────────────────────



  Verify:
  aws sts get-caller-identity --profile claude
