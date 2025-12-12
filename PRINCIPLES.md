# Design Principles & Implementation Report

**Team:** Bahnacy (Front & Back)
**Date:** 2025-12-10

## Applied Principles

> [!NOTE]
> Please fill in the specific lecture numbers and principles based on your course material.

### UI/UX Design
- **Principle:** [e.g., Consistency]
  - **Source:** Lecture [X], Part [Y]
  - **Application:** We maintained a consistent color theme (#000B58, #003161, #006A67, #FDEB9E) across all screens. Input fields and buttons share the same styling.

- **Principle:** [e.g., Visibility of System Status]
  - **Source:** Lecture [X], Part [Y]
  - **Application:** Loading indicators are shown during image upload and submission. Success SnackBar appears upon completion.

### Software Engineering
- **Principle:** [e.g., Separation of Concerns]
  - **Source:** Lecture [X], Part [Y]
  - **Application:** We separated UI code (`screens/`) from business logic (`services/`) and data models (`models/`).

### Security & Data
- **Principle:** [e.g., Data Integrity]
  - **Source:** Lecture [X], Part [Y]
  - **Application:** We implemented a "Soft Duplicate Check" to warn users if they are submitting potentially duplicate data, keeping the database clean.

## Features Implemented
1. **Report Lost Item:**
   - Full form with Image Picker.
   - Uploads to Firebase Storage.
   - Saves to Firestore `items` collection (type: 'lost').
   - Soft Duplicate Warning.

2. **Report Found Item:**
   - Same attributes as Lost.
   - "Handed to Security" toggle (type: 'found').

3. **Navigation:**
   - Bottom Navigation Bar: Home, Activities, Profile.

4. **Theme:**
   - Applied specific color palette.
