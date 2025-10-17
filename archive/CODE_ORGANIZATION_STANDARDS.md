# 📁 Code Organization Standards
## Standard Mandatori per Organizzazione del Codice

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: OBBLIGATORIO PER TUTTI I SERVIZI

---

## 🎯 Principi Fondamentali

### 1. Una Funzione = Un File
- ✅ Ogni funzione deve essere in un file separato
- ✅ Il nome del file deve riflettere esattamente la funzione
- ✅ Massimo una funzione export principale per file
- ✅ Helper functions locali sono permesse se piccole e strettamente correlate

### 2. Documentazione Obbligatoria
- ✅ Ogni funzione deve avere JSDoc/TSDoc completo
- ✅ Commenti inline per logica complessa
- ✅ Examples di utilizzo nel JSDoc
- ✅ Parametri e return value documentati

### 3. Manutenibilità
- ✅ Codice facilmente leggibile anche senza IDE
- ✅ Nessuna magia o trick oscuri
- ✅ Nomi descrittivi e autoesplicativi
- ✅ Facile trovare e modificare singole funzionalità

---

## 📂 Struttura Directory Standard

### Backend Service Structure

```
svc-example/
├── src/
│   ├── index.ts                    # Entry point (orchestration only)
│   ├── config/
│   │   ├── database.ts            # Database configuration
│   │   ├── env.ts                 # Environment variables
│   │   └── constants.ts           # Application constants
│   ├── routes/
│   │   ├── index.ts               # Route aggregation
│   │   ├── users.routes.ts        # User routes definition
│   │   ├── products.routes.ts     # Product routes definition
│   │   └── orders.routes.ts       # Order routes definition
│   ├── controllers/
│   │   ├── users/
│   │   │   ├── createUser.ts      # Create user function
│   │   │   ├── getUser.ts         # Get user by ID
│   │   │   ├── updateUser.ts      # Update user
│   │   │   ├── deleteUser.ts      # Delete user
│   │   │   ├── listUsers.ts       # List users with pagination
│   │   │   └── index.ts           # Export all user controllers
│   │   ├── products/
│   │   │   ├── createProduct.ts
│   │   │   ├── getProduct.ts
│   │   │   ├── updateProduct.ts
│   │   │   └── index.ts
│   │   └── index.ts
│   ├── services/
│   │   ├── users/
│   │   │   ├── validateUserData.ts         # Validate user input
│   │   │   ├── hashPassword.ts             # Hash password
│   │   │   ├── sendWelcomeEmail.ts         # Send welcome email
│   │   │   ├── checkUserExists.ts          # Check if user exists
│   │   │   └── index.ts
│   │   ├── auth/
│   │   │   ├── generateToken.ts            # Generate JWT
│   │   │   ├── verifyToken.ts              # Verify JWT
│   │   │   ├── refreshToken.ts             # Refresh JWT
│   │   │   └── index.ts
│   │   └── index.ts
│   ├── database/
│   │   ├── queries/
│   │   │   ├── users/
│   │   │   │   ├── findUserById.ts         # SQL: Find user by ID
│   │   │   │   ├── findUserByEmail.ts      # SQL: Find user by email
│   │   │   │   ├── insertUser.ts           # SQL: Insert new user
│   │   │   │   ├── updateUserById.ts       # SQL: Update user
│   │   │   │   ├── deleteUserById.ts       # SQL: Delete user
│   │   │   │   └── index.ts
│   │   │   └── index.ts
│   │   └── pool.ts                         # Database connection pool
│   ├── middleware/
│   │   ├── authenticateToken.ts            # JWT authentication
│   │   ├── checkPermission.ts              # Permission check
│   │   ├── validateRequest.ts              # Request validation
│   │   ├── errorHandler.ts                 # Error handling
│   │   ├── requestLogger.ts                # Request logging
│   │   └── index.ts
│   ├── utils/
│   │   ├── formatDate.ts                   # Format date utility
│   │   ├── generateId.ts                   # Generate unique ID
│   │   ├── sanitizeInput.ts                # Sanitize user input
│   │   ├── calculatePagination.ts          # Pagination helper
│   │   └── index.ts
│   ├── types/
│   │   ├── User.ts                         # User type definitions
│   │   ├── Product.ts                      # Product type definitions
│   │   ├── ApiResponse.ts                  # API response types
│   │   └── index.ts
│   └── validators/
│       ├── userSchema.ts                   # User validation schema
│       ├── productSchema.ts                # Product validation schema
│       └── index.ts
├── tests/
│   ├── unit/
│   │   ├── services/
│   │   │   ├── validateUserData.test.ts
│   │   │   └── hashPassword.test.ts
│   │   └── utils/
│   │       └── formatDate.test.ts
│   └── integration/
│       └── users/
│           ├── createUser.test.ts
│           └── getUser.test.ts
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

### Frontend App Structure

```
app-example-frontend/
├── src/
│   ├── main.tsx                    # Entry point
│   ├── App.tsx                     # Root component
│   ├── pages/
│   │   ├── Dashboard/
│   │   │   ├── Dashboard.tsx       # Dashboard page component
│   │   │   ├── Dashboard.hooks.ts  # Custom hooks for dashboard
│   │   │   ├── Dashboard.types.ts  # Dashboard-specific types
│   │   │   └── index.ts
│   │   ├── Users/
│   │   │   ├── UsersList.tsx
│   │   │   ├── UserDetail.tsx
│   │   │   ├── UserForm.tsx
│   │   │   └── index.ts
│   │   └── index.ts
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Header/
│   │   │   │   ├── Header.tsx
│   │   │   │   ├── Header.styles.css
│   │   │   │   └── index.ts
│   │   │   ├── Sidebar/
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   ├── SidebarItem.tsx
│   │   │   │   └── index.ts
│   │   │   └── index.ts
│   │   ├── forms/
│   │   │   ├── Input/
│   │   │   │   ├── Input.tsx
│   │   │   │   ├── Input.types.ts
│   │   │   │   └── index.ts
│   │   │   ├── Select/
│   │   │   ├── Button/
│   │   │   └── index.ts
│   │   └── index.ts
│   ├── hooks/
│   │   ├── useAuth.ts              # Authentication hook
│   │   ├── useApi.ts               # API call hook
│   │   ├── usePagination.ts        # Pagination hook
│   │   ├── useDebounce.ts          # Debounce hook
│   │   └── index.ts
│   ├── api/
│   │   ├── client.ts               # API client setup
│   │   ├── users/
│   │   │   ├── getUsers.ts         # GET /api/users
│   │   │   ├── getUser.ts          # GET /api/users/:id
│   │   │   ├── createUser.ts       # POST /api/users
│   │   │   ├── updateUser.ts       # PUT /api/users/:id
│   │   │   ├── deleteUser.ts       # DELETE /api/users/:id
│   │   │   └── index.ts
│   │   ├── products/
│   │   │   ├── getProducts.ts
│   │   │   ├── getProduct.ts
│   │   │   └── index.ts
│   │   └── index.ts
│   ├── stores/
│   │   ├── authStore.ts            # Auth state management
│   │   ├── userStore.ts            # User state management
│   │   ├── uiStore.ts              # UI state management
│   │   └── index.ts
│   ├── utils/
│   │   ├── formatDate.ts
│   │   ├── formatCurrency.ts
│   │   ├── debounce.ts
│   │   └── index.ts
│   ├── types/
│   │   ├── User.ts
│   │   ├── Product.ts
│   │   ├── Api.ts
│   │   └── index.ts
│   └── constants/
│       ├── routes.ts               # Route constants
│       ├── apiEndpoints.ts         # API endpoint constants
│       └── index.ts
├── public/
├── package.json
├── vite.config.ts
├── tsconfig.json
└── README.md
```

---

## 📝 Documentation Standards

### Function Documentation Template

```typescript
/**
 * Creates a new user in the database
 *
 * @description
 * This function validates user data, hashes the password, checks for existing users,
 * inserts the new user into the database, and sends a welcome email.
 *
 * @param {CreateUserInput} userData - The user data to create
 * @param {string} userData.email - User's email address (must be unique)
 * @param {string} userData.name - User's full name
 * @param {string} userData.password - User's password (will be hashed)
 * @param {string} [userData.role='USER'] - User's role (optional, defaults to 'USER')
 *
 * @returns {Promise<User>} The created user object (without password)
 *
 * @throws {ValidationError} If user data is invalid
 * @throws {ConflictError} If user with email already exists
 * @throws {DatabaseError} If database operation fails
 *
 * @example
 * ```typescript
 * const newUser = await createUser({
 *   email: 'john@example.com',
 *   name: 'John Doe',
 *   password: 'securePass123',
 *   role: 'USER'
 * });
 * console.log(newUser.id); // "uuid-123"
 * ```
 *
 * @see {@link updateUser} for updating user data
 * @see {@link deleteUser} for deleting users
 *
 * @since 1.0.0
 * @author Platform Team
 */
export async function createUser(userData: CreateUserInput): Promise<User> {
  // 1. Validate input data
  const validatedData = await validateUserData(userData);

  // 2. Check if user already exists
  const existingUser = await findUserByEmail(validatedData.email);
  if (existingUser) {
    throw new ConflictError('User with this email already exists');
  }

  // 3. Hash password
  const hashedPassword = await hashPassword(validatedData.password);

  // 4. Insert user into database
  const user = await insertUser({
    ...validatedData,
    password: hashedPassword,
  });

  // 5. Send welcome email (async, don't wait)
  sendWelcomeEmail(user.email, user.name).catch(error => {
    console.error('Failed to send welcome email:', error);
    // Don't throw - email failure shouldn't fail user creation
  });

  // 6. Return user (without password)
  const { password, ...userWithoutPassword } = user;
  return userWithoutPassword;
}
```

### Complex Logic Documentation

```typescript
/**
 * Calculates pagination metadata for API responses
 *
 * @description
 * Given a total count and pagination parameters, calculates:
 * - Total number of pages
 * - Whether there's a next/previous page
 * - Offset for database queries
 *
 * This function handles edge cases like:
 * - page < 1 (defaults to 1)
 * - limit < 1 (defaults to 20)
 * - limit > 100 (capped at 100)
 *
 * @param {Object} params - Pagination parameters
 * @param {number} params.total - Total number of items
 * @param {number} params.page - Current page number (1-indexed)
 * @param {number} params.limit - Items per page
 *
 * @returns {PaginationMetadata} Pagination metadata
 *
 * @example
 * ```typescript
 * const pagination = calculatePagination({
 *   total: 156,
 *   page: 2,
 *   limit: 20
 * });
 * // {
 * //   total: 156,
 * //   page: 2,
 * //   limit: 20,
 * //   pages: 8,
 * //   hasNext: true,
 * //   hasPrev: true,
 * //   offset: 20
 * // }
 * ```
 */
export function calculatePagination(params: {
  total: number;
  page: number;
  limit: number;
}): PaginationMetadata {
  // Validate and normalize inputs
  const page = Math.max(1, params.page); // Ensure page >= 1
  const limit = Math.min(100, Math.max(1, params.limit)); // Clamp limit between 1 and 100

  // Calculate total pages (ceiling division)
  const pages = Math.ceil(params.total / limit);

  // Calculate offset for database query
  // Formula: (page - 1) * limit
  // Example: page 2, limit 20 => offset 20
  const offset = (page - 1) * limit;

  // Check if there are more pages
  const hasNext = page < pages;
  const hasPrev = page > 1;

  return {
    total: params.total,
    page,
    limit,
    pages,
    hasNext,
    hasPrev,
    offset,
  };
}
```

### Database Query Documentation

```typescript
/**
 * Finds a user by ID in the database
 *
 * @description
 * Queries the users table by primary key (id).
 * Returns null if user not found.
 *
 * **Security Note**: This function returns the full user object including
 * the hashed password. Always remove sensitive fields before sending
 * to the client.
 *
 * @param {string} userId - UUID of the user to find
 *
 * @returns {Promise<User | null>} User object or null if not found
 *
 * @throws {DatabaseError} If database query fails
 *
 * @example
 * ```typescript
 * const user = await findUserById('uuid-123');
 * if (user) {
 *   console.log(user.email);
 * } else {
 *   console.log('User not found');
 * }
 * ```
 *
 * @internal This function returns password hash - use getUserById for API
 */
export async function findUserById(userId: string): Promise<User | null> {
  try {
    // Execute query
    const result = await pool.query(
      `
      SELECT
        id,
        email,
        name,
        password,  -- CAUTION: Returns password hash
        role,
        created_at,
        updated_at
      FROM users
      WHERE id = $1
      `,
      [userId]
    );

    // Return first row or null
    return result.rows[0] || null;
  } catch (error) {
    // Log error with context
    console.error('[findUserById] Database error:', error);

    // Throw DatabaseError for consistent error handling
    throw new DatabaseError('Failed to find user by ID', { userId, error });
  }
}
```

### API Function Documentation

```typescript
/**
 * Fetches users from the API with pagination and filtering
 *
 * @description
 * Calls GET /api/users with query parameters for pagination and filtering.
 * Automatically handles authentication via Axios interceptor.
 *
 * @param {Object} [params] - Query parameters (all optional)
 * @param {number} [params.page=1] - Page number (1-indexed)
 * @param {number} [params.limit=20] - Items per page
 * @param {string} [params.role] - Filter by role (e.g., 'ADMIN', 'USER')
 * @param {string} [params.search] - Search in name and email
 * @param {string} [params.sortBy='created_at'] - Sort field
 * @param {string} [params.sortOrder='desc'] - Sort direction ('asc' or 'desc')
 *
 * @returns {Promise<UsersResponse>} Paginated users response
 *
 * @throws {ApiError} If API call fails
 *
 * @example
 * ```typescript
 * // Get first page
 * const users = await getUsers();
 *
 * // Get second page with filtering
 * const admins = await getUsers({
 *   page: 2,
 *   limit: 10,
 *   role: 'ADMIN'
 * });
 *
 * // Search users
 * const results = await getUsers({
 *   search: 'john',
 *   sortBy: 'name',
 *   sortOrder: 'asc'
 * });
 * ```
 */
export async function getUsers(params?: {
  page?: number;
  limit?: number;
  role?: string;
  search?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}): Promise<UsersResponse> {
  try {
    // Make API call with query params
    const response = await apiClient.get<UsersResponse>('/users', {
      params: {
        page: params?.page || 1,
        limit: params?.limit || 20,
        role: params?.role,
        search: params?.search,
        sortBy: params?.sortBy || 'created_at',
        sortOrder: params?.sortOrder || 'desc',
      },
    });

    return response.data;
  } catch (error) {
    // Re-throw with context
    throw new ApiError('Failed to fetch users', { params, error });
  }
}
```

---

## 🔍 Naming Conventions

### Files

```
✅ GOOD:
- createUser.ts
- getUserById.ts
- updateUserPassword.ts
- sendWelcomeEmail.ts
- validateUserData.ts

❌ BAD:
- users.ts (too generic)
- user_create.ts (use camelCase, not snake_case)
- CreateUser.ts (PascalCase only for React components/classes)
- userFunctions.ts (multiple functions in one file)
```

### Functions

```typescript
✅ GOOD:
export async function createUser(data: CreateUserInput): Promise<User>
export function formatDate(date: Date, format: string): string
export async function sendEmail(to: string, subject: string): Promise<void>

❌ BAD:
export async function create(data: any): Promise<any> // Too generic
export function format(d: any): string // Unclear what's being formatted
export async function send(x: string, y: string): Promise<void> // Non-descriptive params
```

### Variables

```typescript
✅ GOOD:
const hashedPassword = await hashPassword(password);
const isUserAdmin = user.role === 'ADMIN';
const totalPages = Math.ceil(total / limit);

❌ BAD:
const hp = await hashPassword(password); // Too short
const flag = user.role === 'ADMIN'; // Non-descriptive
const x = Math.ceil(total / limit); // Meaningless name
```

---

## 🎯 Code Quality Checklist

### Per Function

- [ ] Function has single responsibility
- [ ] Function name clearly describes what it does
- [ ] Function is in its own file
- [ ] File name matches function name
- [ ] JSDoc is complete and accurate
- [ ] All parameters are documented
- [ ] Return value is documented
- [ ] Possible errors are documented
- [ ] At least one example is provided
- [ ] Complex logic has inline comments
- [ ] No magic numbers (use constants)
- [ ] Error handling is present
- [ ] Types are explicit (no `any`)

### Per File

- [ ] File has only one main export
- [ ] Related types are in same file or imported
- [ ] Imports are organized (external, internal, types)
- [ ] File is < 200 lines (split if larger)
- [ ] No dead code
- [ ] No commented-out code
- [ ] Consistent formatting

### Per Module

- [ ] Module has clear purpose
- [ ] index.ts exports public API
- [ ] Private functions are not exported
- [ ] README.md explains module
- [ ] Tests exist for public functions
- [ ] No circular dependencies

---

## 📋 Index Files Pattern

### Barrel Exports

```typescript
// controllers/users/index.ts
export { createUser } from './createUser';
export { getUser } from './getUser';
export { updateUser } from './updateUser';
export { deleteUser } from './deleteUser';
export { listUsers } from './listUsers';

// Now you can import:
// import { createUser, getUser } from '@/controllers/users';
```

### Re-exports with Types

```typescript
// types/index.ts
export type { User } from './User';
export type { Product } from './Product';
export type { Order } from './Order';
export type { ApiResponse } from './ApiResponse';
export type { PaginationMetadata } from './Pagination';
```

---

## 🛠️ Refactoring Existing Code

### Step 1: Identify Functions

```typescript
// BEFORE: users.controller.ts (multiple functions)
export async function createUser(req, res) { ... }
export async function getUser(req, res) { ... }
export async function updateUser(req, res) { ... }
export async function deleteUser(req, res) { ... }
```

### Step 2: Extract to Separate Files

```
controllers/users/
├── createUser.ts
├── getUser.ts
├── updateUser.ts
├── deleteUser.ts
└── index.ts
```

### Step 3: Add Documentation

```typescript
// controllers/users/createUser.ts
/**
 * Creates a new user
 * [Full JSDoc here]
 */
export async function createUser(
  req: Request,
  res: Response
): Promise<void> {
  // Implementation
}
```

### Step 4: Update Imports

```typescript
// routes/users.routes.ts
// BEFORE:
import { createUser, getUser, updateUser } from '../controllers/users.controller';

// AFTER:
import { createUser, getUser, updateUser } from '../controllers/users';
// or
import { createUser } from '../controllers/users/createUser';
import { getUser } from '../controllers/users/getUser';
import { updateUser } from '../controllers/users/updateUser';
```

---

## 🎓 Examples

### Example 1: Simple Utility Function

```typescript
// src/utils/formatCurrency.ts

/**
 * Formats a number as currency with locale-specific formatting
 *
 * @param {number} amount - The amount to format
 * @param {string} [currency='USD'] - ISO 4217 currency code
 * @param {string} [locale='en-US'] - BCP 47 locale code
 *
 * @returns {string} Formatted currency string
 *
 * @example
 * ```typescript
 * formatCurrency(1234.56) // "$1,234.56"
 * formatCurrency(1234.56, 'EUR', 'de-DE') // "1.234,56 €"
 * ```
 */
export function formatCurrency(
  amount: number,
  currency: string = 'USD',
  locale: string = 'en-US'
): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
  }).format(amount);
}
```

### Example 2: Database Query Function

```typescript
// src/database/queries/users/findUsersByRole.ts

import { pool } from '../../pool';
import { User } from '../../../types/User';
import { DatabaseError } from '../../../errors/DatabaseError';

/**
 * Finds all users with a specific role
 *
 * @param {string} role - User role to filter by ('ADMIN', 'USER', etc.)
 * @param {Object} [options] - Query options
 * @param {number} [options.limit] - Maximum number of results
 * @param {number} [options.offset] - Number of results to skip
 *
 * @returns {Promise<User[]>} Array of users with the specified role
 *
 * @throws {DatabaseError} If database query fails
 *
 * @example
 * ```typescript
 * const admins = await findUsersByRole('ADMIN');
 * const users = await findUsersByRole('USER', { limit: 10, offset: 20 });
 * ```
 */
export async function findUsersByRole(
  role: string,
  options?: { limit?: number; offset?: number }
): Promise<User[]> {
  try {
    // Build query with optional pagination
    const query = `
      SELECT
        id,
        email,
        name,
        role,
        created_at,
        updated_at
      FROM users
      WHERE role = $1
      ORDER BY created_at DESC
      ${options?.limit ? `LIMIT $2` : ''}
      ${options?.offset ? `OFFSET $${options?.limit ? 3 : 2}` : ''}
    `;

    // Build params array
    const params: any[] = [role];
    if (options?.limit) params.push(options.limit);
    if (options?.offset) params.push(options.offset);

    // Execute query
    const result = await pool.query(query, params);

    return result.rows as User[];
  } catch (error) {
    console.error('[findUsersByRole] Database error:', error);
    throw new DatabaseError('Failed to find users by role', { role, error });
  }
}
```

### Example 3: API Client Function

```typescript
// src/api/products/updateProduct.ts

import { apiClient } from '../client';
import { Product } from '../../types/Product';
import { ApiError } from '../../errors/ApiError';

/**
 * Update product data
 *
 * @param {string} productId - ID of product to update
 * @param {Partial<Product>} updates - Fields to update
 *
 * @returns {Promise<Product>} Updated product
 *
 * @throws {ApiError} If API call fails
 *
 * @example
 * ```typescript
 * const updated = await updateProduct('prod_123', {
 *   name: 'New Name',
 *   price: 29.99
 * });
 * ```
 */
export async function updateProduct(
  productId: string,
  updates: Partial<Product>
): Promise<Product> {
  try {
    const response = await apiClient.put<Product>(
      `/products/${productId}`,
      updates
    );
    return response.data;
  } catch (error) {
    throw new ApiError('Failed to update product', { productId, error });
  }
}
```

---

## ✅ Summary

### DO:
- ✅ One function per file
- ✅ File name = function name
- ✅ Complete JSDoc for every function
- ✅ Inline comments for complex logic
- ✅ Descriptive names
- ✅ Examples in documentation
- ✅ Index files for barrel exports

### DON'T:
- ❌ Multiple unrelated functions in one file
- ❌ Undocumented functions
- ❌ Magic numbers
- ❌ Generic names (data, result, temp)
- ❌ Commented-out code
- ❌ Using `any` type

---

**Questo standard rende il codice manutenibile, debuggabile e accessibile anche senza IDE.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team
