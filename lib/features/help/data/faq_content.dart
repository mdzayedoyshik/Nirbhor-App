class FaqItem {
  const FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class FaqCategory {
  const FaqCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
  final String title;
  final String icon;
  final List<FaqItem> items;
}

const faqCategories = <FaqCategory>[
  FaqCategory(
    title: 'Getting Started',
    icon: '🚀',
    items: [
      FaqItem(
        question: 'How do I create a flat?',
        answer:
            'On the home screen, tap "Create Flat" and enter your flat\'s name and address. You\'ll become the Manager automatically. Share the join code with your flatmates so they can request to join.',
      ),
      FaqItem(
        question: 'How do I join an existing flat?',
        answer:
            'Tap "Join Flat" on the home screen and enter the 6-character join code your Manager shared. Your request stays pending until the Manager approves it — you\'ll get a notification when that happens.',
      ),
      FaqItem(
        question: 'What is a join code?',
        answer:
            'A unique short code tied to your flat. The Manager can find and share it from the Members section. Anyone with this code can send a join request. You can also share it as a QR code.',
      ),
      FaqItem(
        question: 'What is the difference between Manager, Co-Manager, and Member?',
        answer:
            'The Manager sets up the flat, approves expenses, configures meal settings, verifies payments, manages members, and closes each month. The Co-Manager can help with approvals. Regular Members log their meals, record expenses, and make payments.',
      ),
      FaqItem(
        question: 'Can I change who the Manager is?',
        answer:
            'Yes — the current Manager can transfer their role to any Member. Go to Members, tap a member, and choose "Transfer Manager Role." This cannot be undone unless the new Manager transfers it back.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Meals',
    icon: '🍽️',
    items: [
      FaqItem(
        question: 'How is the meal rate calculated?',
        answer:
            'Each meal shift has a point value (breakfast = 0.5 pts, lunch = 1.0 pt, dinner = 1.0 pt by default). At month end, the total meal expense is divided by the total points across all members. Your cost = your points × rate per point.',
      ),
      FaqItem(
        question: 'What is the meal pool?',
        answer:
            'The meal pool tracks total meal expenses and total meal points for the month. When the Manager approves a meal-type expense, it flows into the pool and the per-point rate updates automatically.',
      ),
      FaqItem(
        question: 'Can I cancel a meal after logging?',
        answer:
            'Yes, as long as the lock time for that shift hasn\'t passed. After the lock time, only the Manager can edit your meal log. The lock time is set by your Manager for each meal shift.',
      ),
      FaqItem(
        question: 'What is the meal shift lock time?',
        answer:
            'A time set by the Manager after which no one can edit their own meal log for that shift. This prevents last-minute changes after the meal is being prepared. The Manager can still edit after the lock time.',
      ),
      FaqItem(
        question: 'What happens if the Manager disables a meal shift?',
        answer:
            'If the Manager turns off a shift for a specific day (e.g., no lunch today), everyone\'s log for that shift is cleared and no meal points are counted. When a shift is re-enabled, previous logs are not restored.',
      ),
      FaqItem(
        question: 'What are meal preferences?',
        answer:
            'Meal preferences let you set your default meals for upcoming days. If you always have lunch and dinner but skip breakfast, set that as your preference and you won\'t have to log those choices every day.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Expenses',
    icon: '🧾',
    items: [
      FaqItem(
        question: 'What are fixed expenses?',
        answer:
            'Monthly recurring costs set by the Manager — rent, utilities, internet, etc. Each member is assigned a fixed contribution amount that gets auto-deducted from their wallet once a month.',
      ),
      FaqItem(
        question: 'How are shared expenses split?',
        answer:
            'Household expenses are split equally among all active members at the time of approval. The cost is deducted from the flat wallet when the Manager approves the expense.',
      ),
      FaqItem(
        question: 'Who can record an expense?',
        answer:
            'Any member can record an expense. However, the Manager must approve it before it affects anyone\'s balance. Pending expenses don\'t count toward the flat wallet until approved.',
      ),
      FaqItem(
        question: 'What are the expense categories?',
        answer:
            '"Meal" expenses flow into the meal pool and affect the per-point meal rate. "Household" expenses are split equally among members. "Fixed" expenses are the recurring monthly contributions.',
      ),
      FaqItem(
        question: 'Can I edit or delete a submitted expense?',
        answer:
            'Only the Manager can edit or delete expenses after they are submitted. If you made a mistake, ask your Manager to correct it.',
      ),
      FaqItem(
        question: 'Why can\'t the month be closed?',
        answer:
            'The month can only close when all submitted expenses for that month have been either approved or rejected. The home screen shows a checklist of blocking expenses that the Manager needs to act on.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Wallet & Payments',
    icon: '💳',
    items: [
      FaqItem(
        question: 'How do I deposit money into my wallet?',
        answer:
            'Tap the Wallet tab → Submit Payment → enter the amount and payment method (bKash, bank transfer, cash, etc.) → submit. The Manager verifies the payment and your balance updates.',
      ),
      FaqItem(
        question: 'What does my wallet balance mean?',
        answer:
            'A negative balance means you owe money to the flat (from fixed contributions, meal costs, or shared expenses). A positive balance means you have credit — you\'ve paid more than you currently owe.',
      ),
      FaqItem(
        question: 'What is a payment request?',
        answer:
            'The Manager can send you a payment request asking you to pay a specific amount. You\'ll see it under Wallet → Requests and can settle it directly from there.',
      ),
      FaqItem(
        question: 'My fixed contribution was auto-deducted. Is that expected?',
        answer:
            'Yes. When the Manager verifies a payment from you, the system checks if your monthly fixed contribution has been deducted yet. If not, it deducts it automatically from your wallet at that point.',
      ),
      FaqItem(
        question: 'Can I pay a partial amount?',
        answer:
            'Yes. When submitting a payment, you can enter any amount — it doesn\'t have to match the full balance. The remaining balance will show as still outstanding.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Monthly Summary',
    icon: '📊',
    items: [
      FaqItem(
        question: 'What is "Close Month"?',
        answer:
            'Closing the month finalizes all balances for that period — meal costs are deducted, expenses are settled, and a permanent summary record is created. After closing, no edits can be made to that month\'s data.',
      ),
      FaqItem(
        question: 'When should the Manager close the month?',
        answer:
            'At the end of each month, once all expenses are approved or rejected and all meals are logged. The Summary screen will tell you exactly what\'s blocking the close if anything is.',
      ),
      FaqItem(
        question: 'How is the final balance calculated at month close?',
        answer:
            'Final balance = fixed contribution + your share of meal costs + your share of household expenses − total payments you made during the month. Positive means you\'re owed; negative means you still owe.',
      ),
      FaqItem(
        question: 'Can I view previous closed months?',
        answer:
            'Yes. In the Summary tab, switch to the History section to see all previously closed months and their complete breakdowns.',
      ),
      FaqItem(
        question: 'What happens to a member\'s balance when they exit the flat?',
        answer:
            'An exit settlement is calculated including their current month\'s meal costs, any owed balance, and fixed contribution refund. Both the member and the flat acknowledge the settlement before the exit is finalized.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Members & Roles',
    icon: '👥',
    items: [
      FaqItem(
        question: 'How do I remove a member from the flat?',
        answer:
            'Only the Manager can initiate a member exit. Go to Members, tap the member, and choose "Initiate Exit." A settlement is calculated, and the member must acknowledge it before being removed.',
      ),
      FaqItem(
        question: 'Can there be more than one Co-Manager?',
        answer:
            'Currently one Co-Manager at a time is supported. The Manager must demote the existing Co-Manager before promoting a new one.',
      ),
      FaqItem(
        question: 'Can a member see other members\' wallet balances?',
        answer:
            'No. Members can only see their own wallet balance and transactions. Only the Manager can see all members\' balances in the "All Wallets" view.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Tasks & Complaints',
    icon: '✅',
    items: [
      FaqItem(
        question: 'How do tasks work?',
        answer:
            'The Manager creates tasks and assigns them to members. Assigned members can update the status (pending → in progress → completed). Tasks appear in the pending actions section on your home screen.',
      ),
      FaqItem(
        question: 'How do I raise a complaint?',
        answer:
            'Go to the Complaints section from your home quick actions, tap the + button, describe the issue, and submit. The Manager and Co-Manager can see all complaints; other members only see their own.',
      ),
      FaqItem(
        question: 'How is a complaint resolved?',
        answer:
            'The Manager reviews the complaint, can respond to it, and marks it as resolved. You\'ll see the status update in the complaint detail view.',
      ),
    ],
  ),
];
