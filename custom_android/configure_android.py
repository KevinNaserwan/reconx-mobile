import os
import shutil

# 1. Update AndroidManifest.xml permissions and service
manifest_path = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(manifest_path):
    with open(manifest_path, 'r') as f:
        c = f.read()
    
    perms = '''
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>
'''
    srv = '''
        <service
            android:name="com.reconx.agent.reconx_mobile.ReconXNotificationListener"
            android:label="ReconX Financial Notification Interceptor"
            android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
            android:exported="true">
            <intent-filter>
                <action android:name="android.service.notification.NotificationListenerService" />
            </intent-filter>
        </service>
'''
    if 'android.permission.CAMERA' not in c:
        c = c.replace('<application', perms + '    <application', 1)
    if 'ReconXNotificationListener' not in c:
        c = c.replace('</application>', srv + '    </application>', 1)
    
    ocr_meta = '''
        <meta-data
            android:name="com.google.mlkit.vision.DEPENDENCIES"
            android:value="ocr" />
'''
    if 'com.google.mlkit.vision.DEPENDENCIES' not in c:
        c = c.replace('</application>', ocr_meta + '    </application>', 1)

    import re
    c = re.sub(r'android:label="[^"]*"', 'android:label="Reconx"', c)
    with open(manifest_path, 'w') as f:
        f.write(c)
    print("AndroidManifest.xml updated successfully.")

# 2. Configure Proguard rules for ML Kit & R8
proguard_src = 'custom_android/proguard-rules.pro'
proguard_dst = 'android/app/proguard-rules.pro'
if os.path.exists(proguard_src):
    shutil.copyfile(proguard_src, proguard_dst)
    print(f"Copied {proguard_src} to {proguard_dst}")
else:
    with open(proguard_dst, 'w') as f:
        f.write("-dontwarn com.google.mlkit.**\n-keep class com.google.mlkit.** { *; }\n-dontwarn com.google_mlkit_text_recognition.**\n-keep class com.google_mlkit_text_recognition.** { *; }\n")
    print("Created default proguard-rules.pro")

# 3. Configure persistent release keystore & disable shrinker in build.gradle
signing_block = """
    signingConfigs {
        release {
            storeFile file('reconx-release.jks')
            storePassword 'reconx2026pass'
            keyAlias 'reconx'
            keyPassword 'reconx2026pass'
        }
    }
"""

for gf in ['android/app/build.gradle', 'android/app/build.gradle.kts']:
    if os.path.exists(gf):
        with open(gf, 'r') as f:
            txt = f.read()
        if 'signingConfigs {' not in txt and 'buildTypes {' in txt:
            txt = txt.replace('buildTypes {', signing_block + '\n    buildTypes {', 1)
        
        # Replace signing config and disable R8 minification/shrinking for MLKit compatibility
        if 'signingConfig signingConfigs.debug' in txt:
            txt = txt.replace(
                'signingConfig signingConfigs.debug',
                'signingConfig signingConfigs.release\n            minifyEnabled false\n            shrinkResources false\n            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"'
            )
        elif 'signingConfig = signingConfigs.debug' in txt:
            txt = txt.replace(
                'signingConfig = signingConfigs.debug',
                'signingConfig = signingConfigs.release\n            minifyEnabled = false\n            shrinkResources = false\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")'
            )
        elif 'signingConfig = signingConfigs.getByName("debug")' in txt:
            txt = txt.replace(
                'signingConfig = signingConfigs.getByName("debug")',
                'signingConfig = signingConfigs.getByName("release")\n            isMinifyEnabled = false\n            isShrinkResources = false\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")'
            )
        with open(gf, 'w') as f:
            f.write(txt)
        print(f"Build configuration and signing configured in {gf}")
