# Real Galaxy FC - Keystore Configuration

## IMPORTANT: DO NOT LOSE THIS INFORMATION

### Production Keystore Details
- **File**: `android/app/real-galaxy-key.keystore`
- **Alias**: `real-galaxy`
- **Password**: `realgalaxyfc26`
- **Key Password**: `realgalaxyfc26`

### Package Name Configuration
- **Package Name**: `com.enochsarkodie.realgalaxyfc`
- **Namespace**: `com.enochsarkodie.realgalaxyfc`
- **Application ID**: `com.enochsarkodie.realgalaxyfc`
- **Google Play Requirement**: ✅ Meets package name requirement

### Certificate Information
- **SHA1**: `2B:7C:D2:22:0C:AB:6E:0F:F1:F3:80:AF:7B:14:90:30:54:89:9C:B1`
- **SHA256**: `58:64:2D:86:3B:A0:B3:54:A8:50:CD:3C:90:52:5F:3A:B4:67:BE:E6:ED:5E:68:86:FA:9A:87:54:34:F0:E0:E3`
- **Algorithm**: SHA384withRSA
- **Key Size**: 2048-bit RSA
- **Validity**: 10,000 days (until 2053)

### Firebase Configuration
- **Package Name**: `com.enochsarkodie.realgalaxyfc`
- **Firebase SHA1**: `2B:7C:D2:22:0C:AB:6E:0F:F1:F3:80:AF:7B:14:90:30:54:89:9C:B1` ✅ MATCH
- **Firebase SHA256**: `D7:23:F8:4B:6A:16:B4:85:25:16:CD:96:45:F2:2E:1F:29:0D:9F:90`
- **Status**: ⚠️ NEEDS UPDATE - Add new app to Firebase project

### Google Play Console
- **Expected SHA1**: `2B:7C:D2:22:0C:AB:6E:0F:F1:F3:80:AF:7B:14:90:30:54:89:9C:B1` ✅ MATCH

### Build Configuration
- **Build.gradle.kts**: Uses `real-galaxy-key.keystore` with alias `real-galaxy`
- **Environment Variables**: Set in `.env` file
- **Version**: 1.0.0+3

### ⚠️ CRITICAL WARNINGS
1. **NEVER** lose the keystore file
2. **NEVER** change the alias or passwords
3. **ALWAYS** backup the keystore file
4. **CERTIFICATE CHANGES**: Possible but requires Firebase + Google Play updates
5. **KEEP** this information secure and accessible

### 🔄 Certificate Change Process (If Needed)
1. **Generate New Keystore**: Create new certificate with different alias
2. **Update Firebase**: Add new SHA1/SHA256 to Firebase Console
3. **Update Google Play**: Upload new AAB - Google Play will manage transition
4. **Test Thoroughly**: Ensure all services work with new certificate
5. **Update Documentation**: Record new certificate details

### Backup Instructions
1. Copy keystore file to secure cloud storage
2. Store this document with the backup
3. Share with trusted team members only
4. Test restore process periodically

### Last Updated
- **Date**: May 7, 2026
- **AAB Built**: Successfully with correct certificate
- **Status**: ✅ Ready for Google Play Console
