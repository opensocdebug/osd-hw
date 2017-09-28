// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

void  hsG_0__0 (struct dummyq_struct * I1208, EBLK  * I1202, U  I669);
void  hsG_0__0 (struct dummyq_struct * I1208, EBLK  * I1202, U  I669)
{
    U  I1451;
    U  I1452;
    U  I1453;
    struct futq * I1454;
    struct dummyq_struct * pQ = I1208;
    I1451 = ((U )vcs_clocks) + I669;
    I1453 = I1451 & ((1 << fHashTableSize) - 1);
    I1202->I721 = (EBLK  *)(-1);
    I1202->I725 = I1451;
    if (I1451 < (U )vcs_clocks) {
        I1452 = ((U  *)&vcs_clocks)[1];
        sched_millenium(pQ, I1202, I1452 + 1, I1451);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I669 == 1)) {
        I1202->I727 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I721 = I1202;
        peblkFutQ1Tail = I1202;
    }
    else if ((I1454 = pQ->I1113[I1453].I739)) {
        I1202->I727 = (struct eblk *)I1454->I738;
        I1454->I738->I721 = (RP )I1202;
        I1454->I738 = (RmaEblk  *)I1202;
    }
    else {
        sched_hsopt(pQ, I1202, I1451);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
