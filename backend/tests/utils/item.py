from sqlmodel import Session

from app import crud
from app.models import Item
from app.schemas import ItemCreate
from tests.utils.user import create_random_user
from tests.utils.utils import random_lower_string


def create_random_item(db: Session) -> Item:
    """
    Create a random item for testing purposes.

    Args:
        db: Database session

    Returns:
        Item: The created item

    Raises:
        ValueError: If owner_id is None
    """
    # Create a random user to be the owner
    user = create_random_user(db)
    owner_id = user.id

    # Validate owner_id
    if owner_id is None:
        raise ValueError("Owner ID cannot be None when creating a random item")

    # Generate random data for the item
    title = random_lower_string()
    description = random_lower_string()

    # Create the item
    item_create = ItemCreate(title=title, description=description)
    return crud.create_item(session=db, item_create=item_create, owner_id=owner_id)
