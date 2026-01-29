#  AppIcon
✅ App Icon & Launch Image — The Only Notes That Matter

✅ Correct way to set the app icon (the only reliable way)
    •    Use one single 1024×1024 image in the host app’s Assets → AppIcon
    •    iOS will automatically generate all sizes from it
    •    Do NOT round corners in the source image
iOS applies rounding and masking itself

⸻

✅ Correct way to set app icon as Launch Image
    1.    Go to Target → Info
    2.    Under Custom iOS Target Properties
    3.    Find or add: Launch Screen → (+ button) Image Name (Do not use UILaunchScreen)
    4.    Set value to: AppIcon
    5.    Done

(Yes, this still works even though Apple barely documents it.)

⸻

✅ App icon in Settings (important gotcha)
    •    The app icon shown in Settings is cached permanently
    •    Once built, it will NOT refresh even if you change icons
    •    To see a new icon in Settings, you must:
    •    Erase device data or
    •    Update iOS or
    •    Change the bundle ID

⚠️ This is a device cache issue, not your app
Other phones, TestFlight, and the App Store will still show the correct icon

⸻

✅ What NOT to do (learned the hard way)
    •    ❌ Do NOT rely on ChatGPT to generate final app icons
It adds padding, masks, and rounded corners, even when explicitly told not to
    •    ❌ Do NOT trust previews — the image may be placed on a white canvas
    •    ❌ Do NOT try to “fix” this in Preview / resize / uncheck proportional — it won’t help

⸻

✅ Correct workflow for making the icon (fast & reliable)
    1.    Use Icon Kitchen
👉 https://icon.kitchen/
    2.    Create the final app icon there
    •    It generates true full-bleed square icons
    •    No hidden padding
    •    Correct iOS behavior
    3.    If you need text split into two lines (e.g.
True
Platsbanken)
    •    Ask ChatGPT only to prepare the text layout or wording
    •    Then apply that layout inside Icon Kitchen

Rule of thumb:

ChatGPT for thinking, Icon Kitchen for pixels

⸻

✅ Summary (tattoo this mentally)
    •    One 1024×1024 AppIcon is enough
    •    iOS handles rounding — you must not
    •    Settings icon cache is permanent
    •    Icon Kitchen solves 90% of icon pain
    •    ChatGPT is not a pixel-perfect design tool
