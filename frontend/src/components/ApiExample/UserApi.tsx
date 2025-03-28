import { Button, Text, VStack } from '@chakra-ui/react';
import { useQuery } from '@tanstack/react-query';
import { UsersService } from '../../client';
import type { UserPublic as User } from '../../client';
import { toaster } from "../../components/ui/toaster";

export default function UserApi() {
  const { data: usersResponse, error, isLoading, refetch } = useQuery<{
    data: User[];
  }, Error>({
    queryKey: ['users'],
    queryFn: async () => {
      try {
        const response = await UsersService.readUsers();
        return response;
      } catch (err) {
        throw err;
      }
    },
  });

  const handleRefetch = () => {
    refetch();
  };

  const users = usersResponse?.data;

  if (isLoading) {
    return (
      <VStack align="stretch" gap={4}>
        <Text>Loading users...</Text>
        <Button onClick={handleRefetch} loading={isLoading}>Refresh Users</Button>
      </VStack>
    );
  }

  if (error) {
    toaster.create({
      title: 'Error fetching users',
      description: error.message,
      type: 'error',
    });
    return (
      <VStack align="stretch" gap={4}>
        <Text color="red.500">Error fetching users: {error.message}</Text>
        <Button onClick={handleRefetch}>Try Again</Button>
      </VStack>
    );
  }

  return (
    <VStack align="stretch" gap={4}>
      {users?.map((user) => (
        <div key={user.id} style={{ border: '1px solid grey', padding: '10px', marginBottom: '10px' }}>
          <Text>ID: {user.id}</Text>
          <Text>Email: {user.email}</Text>
          <Text>Active: {user.is_active ? 'Yes' : 'No'}</Text>
          <Text>Superuser: {user.is_superuser ? 'Yes' : 'No'}</Text>
        </div>
      ))}
      <Button onClick={handleRefetch}>Refetch Users</Button>
    </VStack>
  );
}
