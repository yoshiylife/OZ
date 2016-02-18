/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _QUEUE_H_
#define _QUEUE_H_

/*
 * For queues implemented with liniear list.
 */

#if 0

#define InitQueue(q) \
  (q).first = 0; \
  (q).last = 0

#define QueueFirst(q)  (q).first

#define QueueLast(q)   (q).last

#define InsertQueue(x, q) \
  if ((q).first) \
    (q).last->next = (x); \
  else \
    (q).first = (x); \
  (q).last = (x)

#define RemoveQueue(x, q) \
  if (!QueueIsEmpty(q)) { \
    if (QueueHasOnlyOneElement(q)) { \
      (x) = QueueFirst(q); \
      InitQueue(q); \
    } else { \
      (x) = QueueFirst(q); \
      QueueFirst(q) = QueueFirst(q)->next; \
    } \
  } else \
    (x) = 0

#define QueueIsEmpty(q)  !(q).first

#define QueueHasOnlyOneElement(q) \
  QueueFirst(q) == QueueLast(q)

#endif /* 0 */

/*
 * For queues implemented with binary list.
 */

#define InitQueueBinary(q) (q) = 0

#define InsertQueueBinary(x, q) \
  if (!(q)) { \
    (q) = (x); \
    (x)->b_prev = (x); \
    (x)->b_next = (x); \
  } else { \
    (q)->b_prev->b_next = (x); \
    (x)->b_prev = (q)->b_prev; \
    (q)->b_prev = (x); \
    (x)->b_next = (q); \
  }

#define RemoveQueueBinary(x, q) \
  if ((x) == (x)->b_next) { \
    (q) = 0; \
  } else { \
    (x)->b_prev->b_next = (x)->b_next; \
    (x)->b_next->b_prev = (x)->b_prev; \
    if ((x) == (q)) \
      (q) = (q)->b_next; \
  }


#endif _QUEUE_H_
