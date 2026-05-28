from fastapi import APIRouter
from schemas.extra import FAQListResponse

router = APIRouter(prefix="/faqs", tags=["FAQs"])

STATIC_FAQS = [
    {
        "id": 1,
        "question": "How are caregiver qualifications verified?",
        "answer": "All caregivers on FamCare undergo rigorous credential verification, reference checks, and specialized training alignment to ensure they meet our high medical standards."
    },
    {
        "id": 2,
        "question": "Can I select a preferred caregiver?",
        "answer": "Yes, during the booking process you can handpick qualified caregivers or let our system automatically assign the best caregiver for your scheduled slot."
    },
    {
        "id": 3,
        "question": "What is the booking cancellation policy?",
        "answer": "Bookings can be cancelled up to 24 hours prior to the slot start time without any charge. Late cancellations may incur a nominal fee."
    },
    {
        "id": 4,
        "question": "How is bulk multi-service scheduling priced?",
        "answer": "The platform calculates pricing based on cumulative service rates with full clarity at checkout. All price quotes are clearly itemized in the cart summary."
    }
]

@router.get("", response_model=FAQListResponse)
def get_faqs():
    return {"faqs": STATIC_FAQS}
