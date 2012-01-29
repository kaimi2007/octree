{-# LANGUAGE TemplateHaskell #-}
module TestOctree(main) where

import Octree.Internal
import Prelude hiding(lookup)
import Data.List(sort, sortBy)

{-
import Text.Show
import GHC.Real
-- testing
import Data.Maybe(maybeToList)
import Data.Bits((.&.))
--import Data.Traversable
--import Data.Foldable
-}
import Test.QuickCheck.All(quickCheckAll)
import Test.QuickCheck.Arbitrary


prop_cmp1 a b = cmp a b == joinStep (dx >= 0, dy >= 0, dz >= 0)
  where Coord dx dy dz = a - b

prop_cmp2 a = cmp a origin == joinStep (dx >= 0, dy >= 0, dz >= 0)
  where Coord dx dy dz = a

prop_stepDescription a b = splitStep (cmp a b) == (x a >= x b, y a >= y b, z a >= z b)

prop_octantDistanceNoGreaterThanInterpointDistance0 ptA ptB = triangleInequality 
  where triangleInequality = (octantDistance' aptA (cmp ptB origin)) <= (dist aptA ptB)
        aptA               = abs ptA

prop_octantDistanceNoGreaterThanInterpointDistance ptA ptB vp = triangleInequality || sameOctant
  where triangleInequality = (octantDistance (ptA - vp) (cmp ptB vp)) <= (dist ptA ptB)
        sameOctant         = (cmp ptA vp) == (cmp ptB vp)

prop_octantDistanceNoGreaterThanInterpointDistanceZero ptA ptB = triangleInequality || sameOctant
  where triangleInequality = (octantDistance ptA (cmp ptB origin)) <= (dist ptA ptB)
        sameOctant         = (cmp ptA origin) == (cmp ptB origin)

prop_octantDistanceNoGreaterThanCentroidDistance pt vp = all testFun allOctants
  where testFun odir = (octantDistance (pt - vp) odir) <= dist pt vp

prop_splitByPrime split pt = (unLeaf . octreeStep step $ ot) == [arg]
  where ot   = splitBy' Leaf split [arg] 
        step = cmp pt split
        arg  = (pt, dist pt split)

prop_fromToList         l = sort l == (sort . toList . fromList $ l)
prop_insertionPreserved l = sort l == (sort . toList . foldr insert (Leaf []) $ l)
prop_nearest            l pt = nearest pt (fromList l) == naiveNearest pt l
prop_pickClosest        l pt = pickClosest pt l == naiveNearest pt l
prop_naiveWithinRange   r l pt = naiveWithinRange r pt l == (sort . map fst . withinRange r pt . fromList . tuplify pt $ l)

tuplify pt = map (\a -> (a, dist pt a))

compareDistance pt a b = compare (dist pt (fst a)) (dist pt (fst b))

naiveNearest pt l = if byDist == [] then Nothing else Just . head $ byDist
  where byDist = sortBy (compareDistance pt) l

naiveWithinRange r pt l = sort . filter (\p -> dist pt p <= r) $ l


main = do $quickCheckAll