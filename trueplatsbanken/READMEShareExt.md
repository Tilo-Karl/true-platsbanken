#  iOS Share Extension – Correct Setup (Do Not Deviate)

This is the minimum correct configuration for an iOS Share Extension that actually appears in the system Share Sheet.

If anything here is wrong, iOS silently drops the extension. No errors. No warnings. It just won’t appear.

⸻

1. Create the Share Extension Target

In Xcode:
    •    File → New → Target
    •    Choose Share Extension
    •    Name it (e.g. TBShareExt)
    •    Click Activate when prompted

This creates:
    •    A new target
    •    ShareViewController.swift
    •    A separate Info.plist for the extension

⸻

2. Bundle Identifiers (Must Be Distinct)

Main app:
    •    com.tilodelau.jobtrek

Share extension:
    •    com.tilodelau.jobtrek.TBShareExt

They must NOT be identical.

⸻

3. Info.plist (CRITICAL)

The Share Extension Info.plist must follow this structure exactly:
    •    Root key: NSExtension
    •    NSExtensionAttributes
    •    NSExtensionActivationRule (Dictionary)
    •    NSExtensionActivationSupportsImageWithMaxCount = Integer (e.g. 2)
    •    NSExtensionPointIdentifier = com.apple.share-services
    •    NSExtensionPrincipalClass = $(PRODUCT_MODULE_NAME).ShareViewController

Rules:
    •    NSExtensionActivationRule MUST be inside NSExtensionAttributes
    •    Do NOT place activation keys directly under NSExtension
    •    Do NOT duplicate activation keys elsewhere
    •    Wrong structure = extension never appears

This was the actual bug.

⸻

4. App Groups (Required for Data Sharing)

Both targets must have the same App Group.

In Xcode:
    •    Select main app target → Signing & Capabilities → App Groups
    •    Add: group.com.tilodelau.jobtrek

Repeat for:
    •    TBShareExt target

They must match exactly.

⸻

5. Signing (Leave Automatic Signing ON)
    •    Do NOT disable “Automatically manage signing”
    •    Let Xcode generate provisioning profiles
    •    Ensure both targets are signed with the same team

If App Groups are missing from the signed binary, the extension will not appear.

⸻

6. Embed the Extension

Main app target → Build Phases:
    •    “Embed App Extensions” must contain TBShareExt.appex

If missing, the extension will never load.

⸻

7. ShareViewController Requirements
    •    Must subclass UIViewController (not required to use SLComposeServiceViewController)
    •    Must read data from extensionContext.inputItems
    •    Must call completeRequest(…) to exit

UIHostingController is allowed for SwiftUI.

⸻

8. Testing

Important:
    •    You do NOT “run” the extension directly on device
    •    Build and install the main app
    •    Open any app with Share Sheet (Photos, Safari, Files)
    •    Tap Share → scroll → your app should appear

If it doesn’t:
    •    The configuration is wrong

⸻

9. Known Misleading Logs (Ignore)

This log is NOT the root cause in this project:

“Using kCFPreferencesAnyUser with a container is only allowed for System Containers”

It is a long-standing CoreFoundation warning and NOT why the extension is missing.

The real failure mode is Info.plist structure.

⸻

Final Rule

If the Share Extension does not appear:
    •    Check configuration first
    •    Recheck Info.plist structure first
    •    Only then debug code paths

This bug was caused by incorrect nesting of NSExtensionActivationRule.
