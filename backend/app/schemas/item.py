from uuid import UUID

from sqlmodel import Field, SQLModel


# Shared properties
class ItemBase(SQLModel):
    title: str = Field(min_length=1, max_length=255)
    description: str | None = Field(default=None, max_length=255)


# Properties to receive on item creation
class ItemCreate(ItemBase):
    pass


# Properties to receive on item update
class ItemUpdate(ItemBase):
    title: str | None = Field(default=None, min_length=1, max_length=255)  # type: ignore


# Properties to return via API
class ItemPublic(ItemBase):
    id: UUID
    owner_id: UUID


# Collection of items
class ItemsPublic(SQLModel):
    data: list[ItemPublic]
    count: int
