const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.syncAdminToAdminsCollection = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();
        const userId = context.params.userId;

        // Function to update admin data in "admins" collection
        const updateAdminData = async () => {
            await admin.firestore().collection('admins').doc(userId).set({
                email: newValue.email,
                school_id: newValue.school_id,
                school_name: newValue.school_name,
                full_name: newValue.full_name,
                is_mentor: newValue.is_mentor,
                // ... other fields you want to include
            }, { merge: true }); // Use { merge: true } to update existing fields
        };

        // Check if isAdmin field was changed
        if (newValue.isAdmin !== previousValue.isAdmin) {
            if (newValue.isAdmin) {
                // Add user to "admins" collection
                await updateAdminData();
            } else {
                // Remove user from "admins" collection
                await admin.firestore().collection('admins').doc(userId).delete();
            }
        } else if (newValue.isAdmin) { 
            // If isAdmin is true and other relevant fields changed, update the admin
            if (
                newValue.email !== previousValue.email ||
                newValue.school_id !== previousValue.school_id ||
                newValue.school_name !== previousValue.school_name ||
                newValue.is_mentor !== previousValue.is_mentor ||
                newValue.full_name !== previousValue.full_name
                // ... check for other fields that should trigger an update
            ) {
                await updateAdminData();
            }
        }
    });

