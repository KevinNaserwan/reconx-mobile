import os

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
    
    import re
    c = re.sub(r'android:label="[^"]*"', 'android:label="Reconx"', c)
    with open(manifest_path, 'w') as f:
        f.write(c)
    print("AndroidManifest.xml updated successfully.")

# 2. Configure persistent release keystore in build.gradle
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
            txt = txt.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release')
            txt = txt.replace('signingConfig = signingConfigs.debug', 'signingConfig = signingConfigs.release')
            txt = txt.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
        with open(gf, 'w') as f:
            f.write(txt)
        print(f"Signing configured in {gf}")
