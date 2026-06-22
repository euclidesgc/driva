import { ContainerNode } from "./container";
import { ColumnNode } from "./column";
import { RowNode } from "./row";
import { StackNode } from "./stack";
import { PositionedNode } from "./positioned";
import { TextNode } from "./text";
import { ImageNode } from "./image";
import { IconNode } from "./icon";
import { ButtonNode } from "./button";
import { SizedBoxNode } from "./sizedBox";
import { PaddingNode } from "./padding";
import { CenterNode } from "./center";
import { ExpandedNode } from "./expanded";
import { FlexibleNode } from "./flexible";
import { SpacerNode } from "./spacer";
import { GestureDetectorNode } from "./gestureDetector";
import { WrapNode } from "./wrap";
import { CardNode } from "./card";
import { DividerNode } from "./divider";
import { AlignNode } from "./align";
import { AspectRatioNode } from "./aspectRatio";
import { FractionallySizedBoxNode } from "./fractionallySizedBox";
import { OpacityNode } from "./opacity";
import { SafeAreaNode } from "./safeArea";
import { SingleChildScrollViewNode } from "./singleChildScrollView";

/**
 * Schemas que compõem a união discriminada `Node`.
 * Adicionar um primitivo = adicionar seu arquivo em `nodes/` + uma entrada aqui
 * (+ descriptor em `descriptors/catalog` + builder no renderer).
 */
export const nodeOptions = [
  ContainerNode,
  ColumnNode,
  RowNode,
  StackNode,
  PositionedNode,
  TextNode,
  ImageNode,
  IconNode,
  ButtonNode,
  SizedBoxNode,
  PaddingNode,
  CenterNode,
  ExpandedNode,
  FlexibleNode,
  SpacerNode,
  GestureDetectorNode,
  WrapNode,
  CardNode,
  DividerNode,
  AlignNode,
  AspectRatioNode,
  FractionallySizedBoxNode,
  OpacityNode,
  SafeAreaNode,
  SingleChildScrollViewNode,
] as const;
