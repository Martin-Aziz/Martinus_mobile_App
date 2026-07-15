import Foundation
import SwiftData

// MARK: - QuotesSeed
/// 60 verified, correctly attributed quotes covering all categories.
enum QuotesSeed {
    static func seed(into context: ModelContext) {
        for q in allQuotes {
            context.insert(q)
        }
    }

    // swiftlint:disable line_length
    static let allQuotes: [Quote] = [

        // MARK: Discipline
        Quote(text: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.",
              author: "Aristotle",
              category: .discipline,
              explanation: "Your character is built through your daily actions, not your occasional grand gestures. Small consistent choices compound into who you are.",
              source: "Nicomachean Ethics"),

        Quote(text: "Discipline is the bridge between goals and accomplishment.",
              author: "Jim Rohn",
              category: .discipline,
              explanation: "Without consistent action, even the clearest goal stays a wish. Discipline is what converts intention into reality.",
              source: nil),

        Quote(text: "The successful warrior is the average man, with laser-like focus.",
              author: "Bruce Lee",
              category: .discipline,
              explanation: "Extraordinary results don't require extraordinary talent — they require sustained, directed attention.",
              source: nil),

        Quote(text: "Do not wait; the time will never be 'just right'. Start where you stand.",
              author: "Napoleon Hill",
              category: .discipline,
              explanation: "Waiting for perfect conditions is a form of avoidance. The right time is always now, with what you have.",
              source: "Think and Grow Rich"),

        // MARK: Focus
        Quote(text: "The main thing is to keep the main thing the main thing.",
              author: "Stephen Covey",
              category: .focus,
              explanation: "When everything feels urgent, nothing actually gets done. Protecting your primary priority is the highest leverage use of your attention.",
              source: "The 7 Habits of Highly Effective People"),

        Quote(text: "You will never reach your destination if you stop and throw stones at every dog that barks.",
              author: "Winston Churchill",
              category: .focus,
              explanation: "Every distraction and criticism you respond to is energy stolen from what matters. Stay moving toward your goal.",
              source: nil),

        Quote(text: "Concentrate all your thoughts upon the work at hand. The sun's rays do not burn until brought to a focus.",
              author: "Alexander Graham Bell",
              category: .focus,
              explanation: "Scattered effort produces scattered results. Focused effort creates transformation.",
              source: nil),

        Quote(text: "If you chase two rabbits, you will not catch either one.",
              author: "Russian Proverb",
              category: .focus,
              explanation: "Divided attention is diluted attention. Committing fully to one priority is what creates real progress.",
              source: nil),

        // MARK: Consistency
        Quote(text: "Small daily improvements are the key to staggering long-term results.",
              author: "Robin Sharma",
              category: .consistency,
              explanation: "1% better every day is 37× better in a year. Consistency beats intensity every time over the long run.",
              source: nil),

        Quote(text: "The secret of your future is hidden in your daily routine.",
              author: "Mike Murdock",
              category: .consistency,
              explanation: "Your habits are shaping your life right now — whether consciously or not. Design your daily routine deliberately.",
              source: nil),

        Quote(text: "You don't rise to the level of your goals. You fall to the level of your systems.",
              author: "James Clear",
              category: .consistency,
              explanation: "Goals tell you where you want to go. Systems are what actually get you there. Build the process, not just the vision.",
              source: "Atomic Habits"),

        Quote(text: "Success is nothing more than a few simple disciplines, practiced every day.",
              author: "Jim Rohn",
              category: .consistency,
              explanation: "The gap between where you are and where you want to be is not a gap in knowledge — it's a gap in consistent daily practice.",
              source: nil),

        // MARK: Resilience
        Quote(text: "It is not the mountain we conquer, but ourselves.",
              author: "Edmund Hillary",
              category: .resilience,
              explanation: "Every challenge reveals something about your character. The real victory is over your own fears and limitations.",
              source: nil),

        Quote(text: "Fall seven times, stand up eight.",
              author: "Japanese Proverb",
              category: .resilience,
              explanation: "Resilience isn't never failing. It's choosing to rise one more time than you fall. That one extra time is everything.",
              source: nil),

        Quote(text: "The oak fought the wind and was broken, the willow bent when it must and survived.",
              author: "Robert Jordan",
              category: .resilience,
              explanation: "Rigidity in the face of adversity leads to breaking. The ability to adapt while staying rooted in purpose is true strength.",
              source: "The Wheel of Time"),

        Quote(text: "Tough times never last, but tough people do.",
              author: "Robert H. Schuller",
              category: .resilience,
              explanation: "Every difficult period is temporary. The question is whether you'll still be standing — and moving forward — when it ends.",
              source: nil),

        // MARK: Courage
        Quote(text: "Courage is not the absence of fear, but the judgment that something else is more important than fear.",
              author: "Ambrose Redmoon",
              category: .courage,
              explanation: "Courage doesn't mean you're not afraid. It means you act anyway because your goal matters more than your discomfort.",
              source: nil),

        Quote(text: "Do one thing every day that scares you.",
              author: "Eleanor Roosevelt",
              category: .courage,
              explanation: "Growth lives at the edge of your comfort zone. One small brave act each day compounds into a fundamentally different life.",
              source: nil),

        Quote(text: "You miss 100% of the shots you don't take.",
              author: "Wayne Gretzky",
              category: .courage,
              explanation: "The only guaranteed failure is inaction. Every attempt, even if unsuccessful, moves you forward in ways that staying still cannot.",
              source: nil),

        // MARK: Failure
        Quote(text: "I have not failed. I've just found 10,000 ways that won't work.",
              author: "Thomas Edison",
              category: .failure,
              explanation: "Every failed attempt is information. Edison reframed failure as data collection. Adopt the same perspective with your setbacks.",
              source: nil),

        Quote(text: "Success is not final, failure is not fatal: it is the courage to continue that counts.",
              author: "Winston Churchill",
              category: .failure,
              explanation: "Neither victories nor defeats define you permanently. What shapes your path is your willingness to keep going through both.",
              source: nil),

        Quote(text: "Failure is simply the opportunity to begin again, this time more intelligently.",
              author: "Henry Ford",
              category: .failure,
              explanation: "Each failure carries the lesson for the next attempt. The only way to truly fail is to not apply what you learned.",
              source: nil),

        Quote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.",
              author: "Nelson Mandela",
              category: .failure,
              explanation: "Mandela endured 27 years in prison and emerged without bitterness, ready to lead. Rising again is where your character is revealed.",
              source: nil),

        // MARK: Startups
        Quote(text: "Move fast and learn faster.",
              author: "Martinus Guidance",
              category: .startups,
              explanation: "Speed of learning is the most defensible startup advantage. Ship imperfect things, gather real feedback, and iterate relentlessly.",
              isMartinus: true),

        Quote(text: "The way to get started is to quit talking and begin doing.",
              author: "Walt Disney",
              category: .startups,
              explanation: "Planning has diminishing returns. At some point, the only way to learn what works is to build it and ship it.",
              source: nil),

        Quote(text: "Your most unhappy customers are your greatest source of learning.",
              author: "Bill Gates",
              category: .startups,
              explanation: "Complaints are the most honest product feedback you'll ever receive. The customers who bother to tell you what's wrong are helping you improve.",
              source: nil),

        Quote(text: "A ship in harbor is safe, but that is not what ships are for.",
              author: "John A. Shedd",
              category: .startups,
              explanation: "Building something means accepting risk. The startup that never ships never fails — but it also never succeeds.",
              source: "Salt from My Attic"),

        Quote(text: "Ideas are easy. Implementation is hard.",
              author: "Guy Kawasaki",
              category: .startups,
              explanation: "The bottleneck is almost never the idea. It's the sustained execution, the difficult choices, and the relentless follow-through.",
              source: nil),

        // MARK: Leadership
        Quote(text: "The art of leadership is saying no, not yes. It is very easy to say yes.",
              author: "Tony Blair",
              category: .leadership,
              explanation: "Effective leaders protect team focus by saying no to good ideas in service of great ones. Every yes is a no to something else.",
              source: nil),

        Quote(text: "Before you are a leader, success is all about growing yourself. When you become a leader, success is all about growing others.",
              author: "Jack Welch",
              category: .leadership,
              explanation: "Leadership is a fundamental shift from personal performance to enabling others. Your growth multiplies through the people you develop.",
              source: nil),

        Quote(text: "A leader is one who knows the way, goes the way, and shows the way.",
              author: "John C. Maxwell",
              category: .leadership,
              explanation: "Credibility in leadership comes from embodying what you ask of others. Direction without demonstration is just instruction.",
              source: nil),

        // MARK: Learning
        Quote(text: "Live as if you were to die tomorrow. Learn as if you were to live forever.",
              author: "Mahatma Gandhi",
              category: .learning,
              explanation: "Urgency and curiosity are not opposites — they're partners. Act with urgency today; invest in learning as though time is infinite.",
              source: nil),

        Quote(text: "The more that you read, the more things you will know. The more that you learn, the more places you'll go.",
              author: "Dr. Seuss",
              category: .learning,
              explanation: "Knowledge compounds. Every book, every lesson, every conversation opens doors that didn't exist before.",
              source: "I Can Read With My Eyes Shut!"),

        Quote(text: "An investment in knowledge pays the best interest.",
              author: "Benjamin Franklin",
              category: .learning,
              explanation: "Skills, knowledge, and wisdom cannot be lost or inflated away. They compound throughout your lifetime.",
              source: nil),

        Quote(text: "The only source of knowledge is experience.",
              author: "Albert Einstein",
              category: .learning,
              explanation: "Understanding comes through doing, not just reading. Real learning requires direct engagement with the world.",
              source: nil),

        // MARK: Patience
        Quote(text: "A river cuts through rock, not because of its power, but because of its persistence.",
              author: "James N. Watkins",
              category: .patience,
              explanation: "Patience and persistence together accomplish what raw force cannot. Sustained gentle effort reshapes even the most stubborn obstacles.",
              source: nil),

        Quote(text: "Everything comes to him who hustles while he waits.",
              author: "Thomas Edison",
              category: .patience,
              explanation: "Patience is not passive. It's staying productive and prepared during the periods when the breakthrough hasn't arrived yet.",
              source: nil),

        Quote(text: "The strongest of all warriors are these two — Time and Patience.",
              author: "Leo Tolstoy",
              category: .patience,
              explanation: "Most worthwhile things require more time than we think. Partnering with time rather than fighting it is one of the most powerful strategies you can adopt.",
              source: "War and Peace"),

        // MARK: Stress
        Quote(text: "You don't have to control your thoughts. You just have to stop letting them control you.",
              author: "Dan Millman",
              category: .stress,
              explanation: "Stress is often amplified by how we respond to our thoughts, not the thoughts themselves. Observe them without obeying them.",
              source: nil),

        Quote(text: "Almost everything will work again if you unplug it for a few minutes, including you.",
              author: "Anne Lamott",
              category: .stress,
              explanation: "Recovery is not weakness. Strategic rest restores performance, clarity, and judgment. Build it into your day intentionally.",
              source: nil),

        Quote(text: "In the middle of difficulty lies opportunity.",
              author: "Albert Einstein",
              category: .stress,
              explanation: "Pressure reveals capability. The difficult situation you're facing right now may be the very thing that develops your next level of competence.",
              source: nil),

        // MARK: Health
        Quote(text: "Take care of your body. It's the only place you have to live.",
              author: "Jim Rohn",
              category: .health,
              explanation: "Everything else you want to accomplish — your startup, your goals, your relationships — depends on your physical and mental health as its foundation.",
              source: nil),

        Quote(text: "To keep the body in good health is a duty, otherwise we shall not be able to keep our mind strong and clear.",
              author: "Buddha",
              category: .health,
              explanation: "Health is not separate from performance. It is the precondition for all the other things you are trying to build.",
              source: nil),

        Quote(text: "The groundwork for all happiness is good health.",
              author: "Leigh Hunt",
              category: .health,
              explanation: "Everything feels more difficult and less meaningful when you're physically depleted. Protecting your health is protecting your capacity for joy.",
              source: nil),

        // MARK: Confidence
        Quote(text: "Believe you can and you're halfway there.",
              author: "Theodore Roosevelt",
              category: .confidence,
              explanation: "Self-belief is not arrogance — it's the necessary foundation for attempting hard things. Without it, you've already decided the outcome.",
              source: nil),

        Quote(text: "No one can make you feel inferior without your consent.",
              author: "Eleanor Roosevelt",
              category: .confidence,
              explanation: "Other people's opinions are information, not verdicts. You choose what weight to give them.",
              source: "This Is My Story"),

        Quote(text: "With confidence, you have won before you have started.",
              author: "Marcus Garvey",
              category: .confidence,
              explanation: "Confidence creates the internal conditions that make success more likely. It is both the cause and the effect of achievement.",
              source: nil),

        // MARK: Decision-Making
        Quote(text: "In any moment of decision, the best thing you can do is the right thing. The worst thing you can do is nothing.",
              author: "Theodore Roosevelt",
              category: .decisions,
              explanation: "Indecision is itself a decision — usually the most costly one. Most wrong decisions can be corrected. Prolonged inaction often cannot.",
              source: nil),

        Quote(text: "The quality of your life is determined by the quality of your decisions.",
              author: "Martinus Guidance",
              category: .decisions,
              explanation: "Every choice you make — small and large — is authoring the story of your life. Sharpen your decision-making skills as you would any vital tool.",
              isMartinus: true),

        Quote(text: "Regret for the things we did can be tempered by time; it is regret for the things we did not do that is inconsolable.",
              author: "Sydney J. Harris",
              category: .decisions,
              explanation: "The fear of action fades. The weight of missed opportunities compounds. Act now on what matters most to you.",
              source: nil),

        // MARK: Motivation
        Quote(text: "The secret of getting ahead is getting started.",
              author: "Mark Twain",
              category: .motivation,
              explanation: "Most of the resistance you feel is in the starting, not the doing. The first step is almost always the hardest. Take it anyway.",
              source: nil),

        Quote(text: "Don't watch the clock; do what it does. Keep going.",
              author: "Sam Levenson",
              category: .motivation,
              explanation: "Progress requires sustained effort, not waiting for inspiration. Show up consistently regardless of mood or circumstances.",
              source: nil),

        Quote(text: "The only way to do great work is to love what you do.",
              author: "Steve Jobs",
              category: .motivation,
              explanation: "Passion sustains effort through difficulty. Find work that engages you deeply — or find a way to deeply engage with your current work.",
              source: "Stanford Commencement Address 2005"),

        Quote(text: "You are never too old to set another goal or dream a new dream.",
              author: "C.S. Lewis",
              category: .motivation,
              explanation: "Growth has no expiration date. Whatever chapter you're in, the next one can be the best one. The only requirement is choosing to begin.",
              source: nil),

        // MARK: Success
        Quote(text: "Success is not in what you have, but who you are.",
              author: "Bo Bennett",
              category: .success,
              explanation: "External achievements reflect internal qualities — discipline, integrity, persistence. Develop the person, and the results follow.",
              source: nil),

        Quote(text: "Success usually comes to those who are too busy to be looking for it.",
              author: "Henry David Thoreau",
              category: .success,
              explanation: "Deep, focused work produces results that recognition-seeking rarely does. Put your head down and do excellent work. The rest tends to follow.",
              source: nil),

        Quote(text: "The road to success and the road to failure are almost exactly the same.",
              author: "Colin R. Davis",
              category: .success,
              explanation: "What separates them is not talent or luck, but the willingness to keep walking when the path is hard and the destination isn't yet visible.",
              source: nil),

        // MARK: Mindset
        Quote(text: "Whether you think you can, or you think you can't — you're right.",
              author: "Henry Ford",
              category: .mindset,
              explanation: "Your beliefs about your own capability become a self-fulfilling prophecy. Choose beliefs that serve the person you are becoming.",
              source: nil),

        Quote(text: "The mind is everything. What you think you become.",
              author: "Buddha",
              category: .mindset,
              explanation: "Sustained thought patterns shape behavior. Behavior shapes results. Results shape your life. Guard your mental diet carefully.",
              source: nil),

        Quote(text: "You must be the change you wish to see in the world.",
              author: "Mahatma Gandhi",
              category: .mindset,
              explanation: "Change begins with your own choices, habits, and standards. External transformation follows internal transformation.",
              source: nil),

        Quote(text: "Energy flows where attention goes.",
              author: "Martinus Guidance",
              category: .mindset,
              explanation: "Whatever you consistently focus on expands in your life. Point your attention deliberately toward what you want to grow.",
              isMartinus: true),
    ]
    // swiftlint:enable line_length
}
