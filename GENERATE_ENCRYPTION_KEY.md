# How to Generate and Set MARMOT_SERVER_ENCRYPTION_KEY

## Quick Steps

### Step 1: Generate the Encryption Key

Run this command to generate a secure encryption key:

```bash
docker run --rm ghcr.io/marmotdata/marmot:latest generate-encryption-key
```

**Output Example:**
```
═══════════════════════════════════════════════════════════════
Generated Encryption Key
═══════════════════════════════════════════════════════════════

  xK9mP2qR7vT4wY8zA1bC3dE5fG6hI9jK0lM2nO4pQ6rS8tU1vW3xY5zA7=

═══════════════════════════════════════════════════════════════
Configuration Instructions
═══════════════════════════════════════════════════════════════
...
```

### Step 2: Copy the Generated Key

Copy the key value (the long base64 string) from the output. It will look something like:
```
xK9mP2qR7vT4wY8zA1bC3dE5fG6hI9jK0lM2nO4pQ6rS8tU1vW3xY5zA7=
```

### Step 3: Set in Aiven App Runtime

1. Go to your Aiven App Runtime application settings
2. Navigate to **Environment Variables** section
3. Click **Add environment variable** or **Edit**
4. Set:
   - **Key**: `MARMOT_SERVER_ENCRYPTION_KEY`
   - **Value**: Paste the generated key (the base64 string)
5. Save the configuration

### Step 4: Verify

After deploying, check the application logs. You should see:
```
Encryption key is configured
```

If you see a warning instead, the key wasn't set correctly.

## Alternative: Using Marmot Binary Locally

If you have Marmot installed locally:

```bash
marmot generate-encryption-key
```

Then follow Step 2 and 3 above.

## Important Security Notes

⚠️ **CRITICAL**: 
- **Store this key securely** (password manager, secrets vault)
- **Back up this key** in a secure location
- **Loss of this key** means permanent loss of encrypted credentials
- **Do NOT commit** this key to version control
- **Do NOT share** this key publicly

## What This Key Does

The encryption key is used to encrypt sensitive pipeline credentials (passwords, API keys, tokens) before storing them in the database. Without this key:
- Pipeline credentials will be stored in **plaintext** (if `allow_unencrypted` is enabled)
- Or Marmot will **refuse to start** (if `allow_unencrypted` is false, which is the default)

## Troubleshooting

### "Encryption key is not set" Warning

If you see this warning in logs:
1. Verify the environment variable name is exactly: `MARMOT_SERVER_ENCRYPTION_KEY`
2. Check for typos or extra spaces
3. Ensure the value is the complete base64 string
4. Restart the application after setting the variable

### Key Format

The key must be:
- Base64-encoded
- 32 bytes (44 characters when base64-encoded)
- Generated using cryptographically secure random number generator

Do not try to create your own key manually - always use the `generate-encryption-key` command.
