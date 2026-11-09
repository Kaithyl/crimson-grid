// Modified version of tgui-core InfinitePlane with changes to zoom formula
import {
  type CSSProperties,
  type MouseEvent as ReactMouseEvent,
  type PropsWithChildren,
  useEffect,
  useRef,
  useState,
} from 'react';
import { Button, ProgressBar, Stack } from 'tgui-core/components';

type Props = {
  imageWidth: number;
} & Partial<{
  backgroundImage: string;
  initialLeft: number;
  initialTop: number;
  zoomPadding: number;
  minimumZoom: number;
  maximumZoom: number;
  zoomIncrement: number;
  zoomToX: number;
  zoomToY: number;
  onBackgroundMoved: (newX: number, newY: number) => void;
  onZoomChange: (newZoomValue: number) => void;
  style: CSSProperties;
}> &
  PropsWithChildren;

type ZoomControlsProps = {
  zoom: number;
  padding: number;
  onZoomClick: (
    zoomType: 'increase' | 'decrease',
    zoomX: number,
    zoomY: number,
  ) => void;
  minimumZoom: number;
  maximumZoom: number;
  zoomX: number;
  zoomY: number;
};

const ZoomControls = (props: ZoomControlsProps) => {
  const { zoom, padding, onZoomClick, minimumZoom, maximumZoom, zoomX, zoomY } =
    props;
  return (
    <div style={{ left: 5, position: 'absolute', right: 5 + padding, top: 5 }}>
      <Stack>
        <Stack.Item>
          <Button
            disabled={zoom <= minimumZoom}
            icon="minus"
            onClick={() => onZoomClick('decrease', zoomX, zoomY)}
          />
        </Stack.Item>
        <Stack.Item grow>
          <ProgressBar maxValue={maximumZoom} minValue={minimumZoom} value={zoom}>
            {zoom}x
          </ProgressBar>
        </Stack.Item>
        <Stack.Item>
          <Button
            disabled={zoom >= maximumZoom}
            icon="plus"
            onClick={() => onZoomClick('increase', zoomX, zoomY)}
          />
        </Stack.Item>
      </Stack>
    </div>
  );
};

export const RotePlane = (props: Props) => {
  const {
    backgroundImage,
    children,
    imageWidth,
    zoomPadding = 0,
    initialLeft = 0,
    initialTop = 0,
    minimumZoom = 0.5,
    maximumZoom = 1.5,
    zoomIncrement = 0.1,
    zoomToX = initialLeft,
    zoomToY = initialTop,
    onBackgroundMoved,
    onZoomChange,
    style,
  } = props;

  const [lastX, setLastX] = useState(initialLeft);
  const [lastY, setLastY] = useState(initialTop);
  const [left, setLeft] = useState(initialLeft);
  const [top, setTop] = useState(initialTop);
  const [mouseDown, setMouseDown] = useState(false);
  const [zoom, setZoom] = useState(1);
  const node = useRef<HTMLDivElement | null>(null);

  const handleMouseDown = (event: ReactMouseEvent) => {
    setLastX(event.clientX - left);
    setLastY(event.clientY - top);
    setMouseDown(true);
  };

  const handleMouseMove = (event: ReactMouseEvent) => {
    if (!mouseDown) {
      return;
    }
    const newLastX = event.clientX - lastX;
    const newLastY = event.clientY - lastY;
    onBackgroundMoved?.(newLastX, newLastY);
    setLeft(newLastX);
    setTop(newLastY);
  };

  const handleZoomClick = (
    zoomType: 'increase' | 'decrease',
    zoomX: number,
    zoomY: number,
  ) => {
    if (zoomType === 'increase' && zoom >= maximumZoom) {
      return;
    }
    if (zoomType === 'decrease' && zoom <= minimumZoom) {
      return;
    }
    const newZoom =
      Math.round(
        (zoom + (zoomType === 'increase' ? zoomIncrement : -zoomIncrement)) * 10,
      ) / 10;
    setZoom(newZoom);
    setLeft(((left - zoomX) / zoom) * newZoom + zoomX);
    setTop(((top - zoomY) / zoom) * newZoom + zoomY);
    onZoomChange?.(newZoom);
  };

  useEffect(() => {
    const handleMouseUp = () => setMouseDown(false);
    window.addEventListener('mouseup', handleMouseUp);
    return () => window.removeEventListener('mouseup', handleMouseUp);
  }, []);

  useEffect(() => {
    if (zoomToX !== undefined && zoomToY !== undefined) {
      setLeft(zoomToX);
      setTop(zoomToY);
    }
  }, [zoomToX, zoomToY]);

  useEffect(() => {
    const element = node.current;
    if (!element) {
      return;
    }
    const handleWheel = (event: WheelEvent) => {
      if (event.deltaY === 0) {
        return;
      }
      event.preventDefault();
      const rect = element.getBoundingClientRect();
      handleZoomClick(
        event.deltaY < 0 ? 'increase' : 'decrease',
        event.clientX - rect.left,
        event.clientY - rect.top,
      );
    };
    element.addEventListener('wheel', handleWheel, { passive: false });
    return () => element.removeEventListener('wheel', handleWheel);
  });

  const transition = mouseDown ? '0s' : '0.075s linear';

  return (
    <div
      ref={node}
      style={{
        ...style,
        height: '100%',
        overflow: 'hidden',
        position: 'relative',
        width: '100%',
      }}
    >
      <div
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        style={{
          backgroundImage: `url("${backgroundImage}")`,
          backgroundPosition: `${left}px ${top}px`,
          backgroundRepeat: 'repeat',
          backgroundSize: `${zoom * imageWidth}px`,
          transition,
          height: '100%',
          inset: 0,
          position: 'absolute',
          width: '100%',
        }}
      />
      <div
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        style={{
          height: '100%',
          inset: 0,
          position: 'absolute',
          transform: `translate(${left}px, ${top}px) scale(${zoom})`,
          transition,
          transformOrigin: 'top left',
          width: '100%',
        }}
      >
        {children}
      </div>
      <ZoomControls
        padding={zoomPadding}
        minimumZoom={minimumZoom}
        maximumZoom={maximumZoom}
        zoomX={(node.current?.offsetWidth || 0) / 2}
        zoomY={(node.current?.offsetHeight || 0) / 2}
        onZoomClick={handleZoomClick}
        zoom={zoom}
      />
    </div>
  );
};
