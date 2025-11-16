import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function: Set Custom Claims on user creation
 *
 * Triggers when a new user is created in Firebase Auth.
 * Sets custom claims (role, tenant_id) based on the user data in Hasura.
 */
export const setCustomClaimsOnCreate = functions.auth.user().onCreate(async (user) => {
  try {
    functions.logger.info(`Setting custom claims for user: ${user.uid}`);

    // Get user data from Hasura
    const hasuraEndpoint = process.env.HASURA_GRAPHQL_ENDPOINT || "http://localhost:8080/v1/graphql";
    const hasuraAdminSecret = process.env.HASURA_GRAPHQL_ADMIN_SECRET || "";

    const query = `
      query GetUser($id: uuid!) {
        users_by_pk(id: $id) {
          id
          role
          tenant_id
        }
      }
    `;

    const response = await fetch(hasuraEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-hasura-admin-secret": hasuraAdminSecret,
      },
      body: JSON.stringify({
        query,
        variables: { id: user.uid },
      }),
    });

    const result = await response.json();

    if (result.errors) {
      functions.logger.error("Hasura query error:", result.errors);
      throw new Error("Failed to query user from Hasura");
    }

    const userData = result.data?.users_by_pk;

    if (!userData) {
      functions.logger.warn(`User ${user.uid} not found in Hasura. Skipping custom claims.`);
      return;
    }

    // Set custom claims
    const customClaims = {
      role: userData.role || "user",
      tenant_id: userData.tenant_id,
    };

    await admin.auth().setCustomUserClaims(user.uid, customClaims);

    functions.logger.info(`Custom claims set for user ${user.uid}:`, customClaims);
  } catch (error) {
    functions.logger.error("Error setting custom claims:", error);
    // Don't throw - allow user creation to succeed even if claims fail
  }
});

/**
 * Callable Function: Manually refresh user's custom claims
 *
 * Can be called from the client to force a claims refresh
 * (useful after role/tenant changes)
 */
export const refreshCustomClaims = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const uid = context.auth.uid;

  try {
    functions.logger.info(`Refreshing custom claims for user: ${uid}`);

    // Get user data from Hasura
    const hasuraEndpoint = process.env.HASURA_GRAPHQL_ENDPOINT || "http://localhost:8080/v1/graphql";
    const hasuraAdminSecret = process.env.HASURA_GRAPHQL_ADMIN_SECRET || "";

    const query = `
      query GetUser($id: uuid!) {
        users_by_pk(id: $id) {
          id
          role
          tenant_id
        }
      }
    `;

    const response = await fetch(hasuraEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-hasura-admin-secret": hasuraAdminSecret,
      },
      body: JSON.stringify({
        query,
        variables: { id: uid },
      }),
    });

    const result = await response.json();

    if (result.errors) {
      functions.logger.error("Hasura query error:", result.errors);
      throw new functions.https.HttpsError("internal", "Failed to query user from Hasura");
    }

    const userData = result.data?.users_by_pk;

    if (!userData) {
      throw new functions.https.HttpsError("not-found", "User not found in database");
    }

    // Set custom claims
    const customClaims = {
      role: userData.role || "user",
      tenant_id: userData.tenant_id,
    };

    await admin.auth().setCustomUserClaims(uid, customClaims);

    functions.logger.info(`Custom claims refreshed for user ${uid}:`, customClaims);

    return {
      success: true,
      claims: customClaims,
    };
  } catch (error) {
    functions.logger.error("Error refreshing custom claims:", error);
    throw new functions.https.HttpsError("internal", "Failed to refresh custom claims");
  }
});
