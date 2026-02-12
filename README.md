# StaffVault: Smart Employee & Salary Manager

[![Download APK](https://img.shields.io/badge/Download-StaffVault%20APK-blue?style=for-the-badge&logo=android)](https://github.com/PtlLuv27/staffvault/releases/download/v1.0.0/staffvault.apk)

**StaffVault** is a robust, offline-first mobile application designed to manage employee attendance, salary calculations, and professional financial reports. Built with a focus on reliability, it ensures your business data is always available locally and securely backed up to the cloud.



---

## 🚀 Key Features

### 1. Offline-First Architecture
* **Local Database**: Uses a high-performance SQLite database to store all employee profiles and attendance logs locally on your device.
* **Zero Latency**: Perform all daily tasks—marking attendance, adding employees, or viewing salaries—without needing an active internet connection.

### 2. Unified Cloud Synchronization
* **Firebase Firestore Sync**: Automatically mirrors local data to the cloud whenever you are online.
* **Cross-Device Consistency**: Your data is linked to your unique Firebase UID, ensuring you never lose a record even if you switch phones.
* **Unified Authentication**: Supports both **Google Sign-In** and **Email/Password** login.
* **Smart Security**: New Google users are automatically prompted to set a password, enabling dual login methods for the same account.

### 3. Employee & Attendance Tracking
* **Management Hub**: A dedicated "Manage Employees" screen to create, edit, or remove staff profiles.
* **Flexible Statuses**: Mark employees as **Present**, **Absent**, or **Half-day** with a single tap.
* **Add-on Tracking**: Add bonuses or record loans (UPAD) directly within the daily attendance logs.

### 4. Financial Analytics & Reporting
* **Interactive Dashboard**: Real-time summary of today's attendance with visual Pie Charts.
* **Salary Dashboard**: Detailed monthly payout overview with a month-picker filter.
* **Professional PDF Ledgers**: Generates a 1st-to-31st daily breakdown report featuring earnings, bonuses, loans, and notes.
* **Net Salary Logic**: Automatic color-coding (Green for positive, Red for negative) to track employee financial status.

---

## 🛠 Tech Stack

| Category | Technology Used |
| :--- | :--- |
| **Frontend** | Flutter (Dart) |
| **UI Framework** | Material Design 3 |
| **Local Database** | SQLite (sqflite) |
| **Cloud Backend** | Firebase Firestore |
| **Authentication** | Firebase Auth (Google & Email/Password) |
| **Visual Analytics** | fl_chart |
| **Document Export** | pdf & printing packages |

---

## 📥 Installation & Setup

### **For Users**
The easiest way to get started is to download the latest APK directly:
* [**Download staffvault.apk v1.0.0**](https://github.com/PtlLuv27/staffvault/releases/download/v1.0.0/staffvault.apk)

### **For Developers**
1.  **Clone the Repository**:
    ```bash
    git clone [https://github.com/PtlLuv27/staffvault.git](https://github.com/PtlLuv27/staffvault.git)
    cd staffvault
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Configure Firebase**:
    * Place your `google-services.json` in the `android/app/` directory.
    * Enable **Email/Password** and **Google** providers in the Firebase Console.
4.  **Launch the App**:
    ```bash
    flutter run
    ```

### Building the APK
To generate the production file **staffvault.apk**:
1.  Build the release:
    ```bash
    flutter build apk --release
    ```
2.  Find the file at `build/app/outputs/flutter-apk/app-release.apk` and rename it to `staffvault.apk`.

---

## 🤝 Support
For issues, feature requests, or contributions, please open an issue in the GitHub repository.

---
