# 🚀 TankToad App Application

Welcome to our awesome TankToad App application! This guide will help you set up and run both the backend and frontend of our project. Let's get started! 😎

## 📋 Prerequisites

Before we begin, make sure you have the following tools installed:

1. 🖥️ Visual Studio
2. 💻 Visual Studio Code
3. 📱 Android Studio

## 🛠️ Setup

### 1. Install Flutter

1. Download and install Flutter from the official website: https://flutter.dev/docs/get-started/install
2. Add Flutter to your PATH
3. Run `flutter doctor` in your terminal to verify the installation

### 2. Set up the Backend (.NET)

1. Open Visual Studio
2. Clone the backend repository
3. Open the solution file
4. Restore NuGet packages
5. Build the solution

### 3. Set up the Frontend (Flutter)

1. Open Visual Studio Code
2. Clone the frontend repository
3. Open the project folder
4. Run `flutter pub get` in the terminal to install dependencies
5. 🔑 Create a `.env` file in the project root with the following content:
   ```
   API_URL=http://10.0.2.2:5000/
   LOGIN_ENDPOINT=Users/authenticate
   DEVICES_LIST=api/MobileApp?userListId=
   ```

### 4. Create an Android Emulator

1. Open Android Studio
2. Go to Tools > AVD Manager
3. Click on "Create Virtual Device"
4. Choose a device definition (e.g., Pixel 4)
5. Select a system image (e.g., Android 11)
6. Finish the emulator setup

## 🏃‍♂️ Running the Application

### 1. Start the Backend

1. In Visual Studio, set the API project as the startup project
2. Press F5 or click the "Start Debugging" button
3. The backend should now be running on `https://localhost:5001`

### 2. Run the Flutter Frontend

1. In Visual Studio Code, open a terminal
2. Ensure you have a device connected or an emulator running
3. Run the following commands:
   ```
   flutter clean
   flutter pub get
   flutter run
   ```
4. The app should now be running on your device or emulator

## 🧹 Cleaning and Updating Dependencies

If you encounter any issues or want to ensure you have the latest dependencies, you can use the following commands:

1. Clean the project:
   ```
   flutter clean
   ```
2. Get the latest dependencies:
   ```
   flutter pub get
   ```

## 🎉 Congratulations!

You've successfully set up and run the TankToad App application. Happy coding! 🚀👨‍💻👩‍💻

If you have any questions or run into issues, please don't hesitate to reach out to our support team. Good luck with your development!