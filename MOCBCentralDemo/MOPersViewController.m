//
//  MOBleListViewController.m
//  MOBleDemo
//
//  Created by 莫晓卉 on 2018/12/10.
//  Copyright © 2018 moxiaohui. All rights reserved.
//

#import "MOPersViewController.h"
#import "MOSersViewController.h"
#import "MOBLEManager.h"

@interface MOPersViewController () <UITableViewDataSource, UITableViewDelegate, MOBLEManagerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *leftBtn;
@property (nonatomic, strong) UIButton *rightBtn;
@end

@implementation MOPersViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupView];
  [[MOBLEManager shareInstance] addDelegate:self];

  // pcm -> wav
//  NSString *pcmPath = [[NSBundle mainBundle] pathForResource:@"burstdata_vad" ofType:@"pcm"];
//  NSLog(@"pcmData %@", pcmPath);
//  NSData *data = [NSData dataWithContentsOfFile:pcmPath];
//  NSLog(@"pcmData.length %lu", (unsigned long)data.length);
//  [[MOBLEManager shareInstance] getAndCreatePlayableFileFromPcmData:pcmPath];
}

- (void)setupView {
  self.title = @"蓝牙列表";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBtn];
  
  CGFloat topHeight = CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame) + 44;
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topHeight, self.view.frame.size.width, self.view.frame.size.height - topHeight) style:UITableViewStylePlain];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
  self.tableView.tableFooterView = view;
  [self.view addSubview:self.tableView];
}

- (void)refreshAction:(UIButton *)sender {
  sender.selected = !sender.selected;
  if (sender.selected) {
    [[MOBLEManager shareInstance] startScan];
  } else {
    [[MOBLEManager shareInstance] stopScan];
  }
}

#pragma mark - MOBLEManagerDelegate
- (void)discoverPeripheral {
  [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  MOSersViewController *vc = [MOSersViewController new];
  vc.per = [MOBLEManager shareInstance].peripheralArr[indexPath.row];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIndentify = @"UITableViewCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentify];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIndentify];
  }
  CBPeripheral *per = [MOBLEManager shareInstance].peripheralArr[indexPath.row];
  cell.textLabel.text = per.name;
  cell.detailTextLabel.text = per.identifier.UUIDString;
  
  // --- 方便测试
//  if ([per.name containsString:@"Earbud"]) {
//    [[MOBLEManager shareInstance] stopScan];
//    MOSersViewController *vc = [MOSersViewController new];
//    vc.per = per;
//    [self.navigationController pushViewController:vc animated:YES];
//  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 50;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [MOBLEManager shareInstance].peripheralArr.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  return [UIView new];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 0.001;
}

- (UIButton *)rightBtn {
  if (!_rightBtn) {
    _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _rightBtn.frame = CGRectMake(0, 0, 44, 44);
    [_rightBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [_rightBtn setTitleColor:UIColor.redColor forState:UIControlStateSelected];
    [_rightBtn addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventTouchUpInside];
    [_rightBtn setTitle:@"扫描" forState:UIControlStateNormal];
    [_rightBtn setTitle:@"停止" forState:UIControlStateSelected];
    _rightBtn.selected = YES;
  }
  return _rightBtn;
}

@end
