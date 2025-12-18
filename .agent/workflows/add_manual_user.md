---
description: How to manually add a new user to the database (Auth + Firestore)
---

This workflow describes how to use the `add_user_script.dart` to manually register a user, bypassing the app's registration screen.

1.  **Open the Script**
    Open the file `lib/add_user_script.dart` in your editor.

2.  **Edit User Details**
    Locate the `authService.registerUser` call inside the `main()` function and update the parameters with the new user's information:

    ```dart
    final user = await authService.registerUser(
      name: 'NEW NAME',
      email: 'NEW_EMAIL@f-eng.tanta.edu.eg',
      password: 'NEW_PASSWORD',
      phoneNumber: 'NEW_PHONE',
    );
    ```

3.  **Run the Script**
    Execute the following command in your terminal to run the script via Chrome (since Windows device might not be available/configured):
    
    ```bash
    flutter run -t lib/add_user_script.dart -d chrome
    ```

4.  **Verify**
    Check the console output for `SUCCESS: User added successfully.` and the new UID.
