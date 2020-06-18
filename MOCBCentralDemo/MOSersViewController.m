//
//  MOPerViewController.m
//  MOBleDemo
//
//  Created by 莫晓卉 on 2018/12/10.
//  Copyright © 2018 moxiaohui. All rights reserved.
//

#import "MOSersViewController.h"
#import "MOChasViewController.h"
#import "MOBLEManager.h"

@interface MOSersViewController () <MOBLEManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *services;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *nameLb;
@end

@implementation MOSersViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupView];
}

- (void)setPer:(CBPeripheral *)per {
  _per = per;
  self.nameLb.text = @"连接并搜索服务中...";
  [self.tableView reloadData];
  [[MOBLEManager shareInstance] addDelegate:self];
  [[MOBLEManager shareInstance] connectPer:_per];
}

#pragma mark - MOBLEManagerDelegate
- (void)didDiscoverServices:(NSError *)error {
  self.services = [MOBLEManager shareInstance].connectPer.services;
  NSLog(@"didDiscoverServices:%@", self.services);
  if (error) {
    self.nameLb.text = [NSString stringWithFormat:@"获取service失败 %@\n%@\n%@", _per.name, _per.identifier, error.description];
  } else {
    self.nameLb.text = [NSString stringWithFormat:@"%@\n%@", _per.name, _per.identifier];
  }
  [self.tableView reloadData];
}

- (void)didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
  self.nameLb.text = [NSString stringWithFormat:@"连接失败 %@\n%@\n%@", peripheral.name, peripheral.identifier, error.description];
  [self.tableView reloadData];
}
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
  self.nameLb.text = [NSString stringWithFormat:@"断开连接 %@\n%@\n%@", peripheral.name, peripheral.identifier, error.description];
  [self.tableView reloadData];
}

- (void)setupView {
  self.title = @"服务列表";
  CGFloat topHeight = CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame) + 44;
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topHeight, self.view.frame.size.width, self.view.frame.size.height - topHeight) style:UITableViewStylePlain];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, CGFLOAT_MIN)];
  self.tableView.tableFooterView = view;
  [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  MOChasViewController *vc = [MOChasViewController new];
  vc.service = self.services[indexPath.row];
  [self.navigationController pushViewController:vc animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIndentify = @"UITableViewCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentify];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIndentify];
  }
  cell.textLabel.font = [UIFont systemFontOfSize:14];
  cell.textLabel.numberOfLines = 0;
  cell.contentView.backgroundColor = indexPath.row % 2 == 0 ? UIColor.lightGrayColor : UIColor.whiteColor;
  CBService *service = self.services[indexPath.row];
  cell.textLabel.text = service.UUID.UUIDString;
  cell.textLabel.textColor = [UIColor redColor];
  cell.detailTextLabel.text = service.description;
  cell.detailTextLabel.textColor = [UIColor blackColor];
  cell.detailTextLabel.numberOfLines = 0;
  // --- 方便测试
//  if ([service.UUID.UUIDString containsString:@"8866"]) {
//    MOChasViewController *vc = [MOChasViewController new];
//    vc.service = self.services[indexPath.row];
//    [self.navigationController pushViewController:vc animated:YES];
//  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 80;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.services.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  return [UIView new];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return self.headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 100;
}

- (UIView *)headerView {
  if (!_headerView) {
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    _headerView.backgroundColor = UIColor.whiteColor;
    [_headerView addSubview:self.nameLb];
    self.nameLb.center = _headerView.center;
  }
  return _headerView;
}

- (UILabel *)nameLb {
  if (!_nameLb) {
    _nameLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    _nameLb.textColor = UIColor.blueColor;
    _nameLb.font = [UIFont systemFontOfSize:14];
    _nameLb.numberOfLines = 0;
  }
  return _nameLb;
}

@end
