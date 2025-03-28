import { http, HttpResponse } from 'msw';

// Define handlers for API endpoints
export const handlers = [
  // User endpoints
  http.get('/api/v1/users/me', () => {
    return HttpResponse.json({
      id: 1,
      email: 'admin@example.com',
      full_name: 'Test User',
      is_active: true,
      is_superuser: true
    });
  }),
  
  http.get('/api/v1/users/', () => {
    return HttpResponse.json([
      {
        id: 1,
        email: 'admin@example.com',
        full_name: 'Test User',
        is_active: true,
        is_superuser: true
      },
      {
        id: 2,
        email: 'user@example.com',
        full_name: 'Regular User',
        is_active: true,
        is_superuser: false
      }
    ]);
  }),
  
  http.post('/api/v1/users/', async ({ request }) => {
    const userData = await request.json() as { email: string, password: string };
    return HttpResponse.json({
      id: 3,
      email: userData.email,
      is_active: true,
      is_superuser: false
    });
  }),
  
  // Auth endpoints
  http.post('/api/v1/auth/login', async ({ request }) => {
    const credentials = await request.json() as { username: string, password: string };
    
    if (credentials.username === 'admin@example.com' && credentials.password === 'password') {
      return HttpResponse.json({
        access_token: 'mock-token',
        token_type: 'bearer'
      });
    }
    
    return new HttpResponse(null, { status: 401 });
  }),
  
  // Error handling
  http.get('/api/v1/error-test', () => {
    return new HttpResponse(null, { status: 500 });
  })
];
